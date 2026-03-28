import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Conversation } from './schemas/conversation.schema';
import { Message } from './schemas/message.schema';

@Injectable()
export class ChatService {
  constructor(
    @InjectModel(Conversation.name)
    private readonly conversationModel: Model<Conversation>,
    @InjectModel(Message.name)
    private readonly messageModel: Model<Message>,
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

  async getUserConversations(userId: string): Promise<Conversation[]> {
    return this.conversationModel
      .find({ participants: userId })
      .sort({ updatedAt: -1 })
      .exec();
  }

  async getMessages(
    conversationId: string,
    page = 1,
    limit = 50,
  ): Promise<Message[]> {
    return this.messageModel
      .find({ conversationId })
      .sort({ sentAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .exec();
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
