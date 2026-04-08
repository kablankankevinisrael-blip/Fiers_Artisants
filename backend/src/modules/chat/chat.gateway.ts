import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { ChatService } from './chat.service';

@WebSocketGateway({
  namespace: '/ws/chat',
  cors: { origin: '*' },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);
  private userSockets = new Map<string, string>(); // userId -> socketId

  private toClientMessage(message: any) {
    if (!message) return message;
    const plain = typeof message.toObject === 'function' ? message.toObject() : message;
    return {
      ...plain,
      id: plain?._id?.toString?.() ?? plain?.id?.toString?.() ?? '',
      _id: plain?._id?.toString?.() ?? plain?.id?.toString?.() ?? '',
    };
  }

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    if (userId) {
      this.userSockets.set(userId, client.id);
      this.logger.log(`User ${userId} connected`);
    }
  }

  handleDisconnect(client: Socket) {
    const userId = [...this.userSockets.entries()].find(
      ([, socketId]) => socketId === client.id,
    )?.[0];
    if (userId) {
      this.userSockets.delete(userId);
      this.logger.log(`User ${userId} disconnected`);
    }
  }

  constructor(private readonly chatService: ChatService) {}

  @SubscribeMessage('joinConversation')
  handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    client.join(`conversation:${data.conversationId}`);
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      conversationId: string;
      senderId: string;
      content: string;
      type?: string;
      mediaUrl?: string;
    },
  ) {
    const message = await this.chatService.sendMessage(
      data.conversationId,
      data.senderId,
      data.content,
      data.type,
      data.mediaUrl,
    );

    const payload = this.toClientMessage(message);

    // Émettre aux participants de la conversation
    this.server
      .to(`conversation:${data.conversationId}`)
      .emit('newMessage', payload);

    return payload;
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @MessageBody()
    data: { conversationId: string; userId: string },
  ) {
    await this.chatService.markAsRead(data.conversationId, data.userId);
    this.server
      .to(`conversation:${data.conversationId}`)
      .emit('messagesRead', { conversationId: data.conversationId, userId: data.userId });
  }
}
