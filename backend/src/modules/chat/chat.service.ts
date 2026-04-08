import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { InjectRepository } from '@nestjs/typeorm';
import { Model } from 'mongoose';
import { Repository, In } from 'typeorm';
import { Conversation } from './schemas/conversation.schema';
import { Message } from './schemas/message.schema';
import { User } from '../users/entities/user.entity';
import { ArtisanProfile } from '../users/entities/artisan-profile.entity';
import { ClientProfile } from '../users/entities/client-profile.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<Conversation>,
    @InjectModel(Message.name)
    private readonly messageModel: Model<Message>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ArtisanProfile)
    private readonly artisanProfileRepository: Repository<ArtisanProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
  ) {}

  async createConversation(
    participantIds: string[],
  ): Promise<Conversation> {
    // Vérifier si la conversation existe déjà
    const existing = await this.conversationModel.findOne({
      participants: { $all: participantIds, $size: participantIds.length },
    });
    if (existing) return existing;

    return this.conversationModel.create({
      participants: participantIds,
    });
  }

  async getUserConversations(userId: string) {
    const conversations = await this.conversationModel
      .find({ participants: userId })
      .sort({ updatedAt: -1 })
      .lean()
      .exec();

    // Collect all other participant IDs
    const otherIds = new Set<string>();
    for (const c of conversations) {
      for (const p of c.participants) {
        if (p !== userId) otherIds.add(p);
      }
    }

    // Resolve names from profiles
    const nameMap = await this.resolveParticipantNames(Array.from(otherIds));

    // Count unread per conversation
    const convoIds = conversations.map((c) => c._id.toString());
    const unreadCounts = await this.messageModel.aggregate([
      {
        $match: {
          conversationId: { $in: convoIds },
          senderId: { $ne: userId },
          isRead: false,
        },
      },
      { $group: { _id: '$conversationId', count: { $sum: 1 } } },
    ]);
    const unreadMap = new Map<string, number>();
    for (const u of unreadCounts) {
      unreadMap.set(u._id, u.count);
    }

    return conversations.map((c) => {
      const otherId = c.participants.find((p: string) => p !== userId) || '';
      return {
        _id: c._id,
        participantId: otherId,
        participantName: nameMap.get(otherId) || 'Utilisateur',
        lastMessage: c.lastMessage,
        unreadCount: unreadMap.get(c._id.toString()) || 0,
        updatedAt: (c as any).updatedAt,
      };
    });
  }

  private async resolveParticipantNames(
    userIds: string[],
  ): Promise<Map<string, string>> {
    if (userIds.length === 0) return new Map();

    const nameMap = new Map<string, string>();

    // Fetch user roles
    const users = await this.userRepository.find({
      where: { id: In(userIds) },
      select: ['id', 'role', 'phone_number'],
    });
    const roleMap = new Map(users.map((u) => [u.id, u]));

    const artisanIds = users
      .filter((u) => u.role === 'ARTISAN')
      .map((u) => u.id);
    const clientIds = users
      .filter((u) => u.role === 'CLIENT')
      .map((u) => u.id);

    if (artisanIds.length > 0) {
      const profiles = await this.artisanProfileRepository.find({
        where: { user_id: In(artisanIds) },
        select: ['id', 'user_id', 'first_name', 'last_name', 'business_name'],
      });
      for (const p of profiles) {
        nameMap.set(
          p.user_id,
          p.business_name || `${p.first_name} ${p.last_name}`,
        );
      }
    }

    if (clientIds.length > 0) {
      const profiles = await this.clientProfileRepository.find({
        where: { user_id: In(clientIds) },
        select: ['id', 'user_id', 'first_name', 'last_name'],
      });
      for (const p of profiles) {
        nameMap.set(p.user_id, `${p.first_name} ${p.last_name}`);
      }
    }

    // Fallback to phone for users without a profile
    for (const u of users) {
      if (!nameMap.has(u.id)) {
        nameMap.set(u.id, u.phone_number);
      }
    }

    return nameMap;
  }

  async getMessages(
    conversationId: string,
    page = 1,
    limit = 50,
  ): Promise<Message[]> {
    const messages = await this.messageModel
      .find({ conversationId })
      // Return latest messages first, then re-order in ascending order for UI rendering.
      .sort({ sentAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .exec();

    return messages.reverse();
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    content: string,
    type = 'TEXT',
    mediaUrl?: string,
  ): Promise<Message> {
    const conversation = await this.conversationModel.findById(conversationId);
    if (!conversation) {
      throw new NotFoundException('Conversation non trouvée.');
    }

    const message = await this.messageModel.create({
      conversationId,
      senderId,
      content,
      type,
      mediaUrl,
    });

    // Mettre à jour le dernier message de la conversation
    await this.conversationModel.findByIdAndUpdate(conversationId, {
      lastMessage: {
        content,
        sentAt: new Date(),
        senderId,
      },
    });

    return message;
  }

  async markAsRead(conversationId: string, userId: string): Promise<void> {
    await this.messageModel.updateMany(
      { conversationId, senderId: { $ne: userId }, isRead: false },
      { isRead: true },
    );
  }
}
