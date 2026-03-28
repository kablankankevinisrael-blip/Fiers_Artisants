import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export enum MessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  SYSTEM = 'SYSTEM',
}

@Schema({ collection: 'messages' })
export class Message extends Document {
  @Prop({ required: true, index: true })
  conversationId: string;

  @Prop({ required: true })
  senderId: string;

  @Prop({ required: true })
  content: string;

  @Prop({ type: String, enum: MessageType, default: MessageType.TEXT })
  type: MessageType;

  @Prop()
  mediaUrl: string;

  @Prop({ default: false })
  isRead: boolean;

  @Prop({ default: () => new Date() })
  sentAt: Date;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
