import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'portfolio_items', timestamps: true })
export class PortfolioItem extends Document {
  @Prop({ required: true, index: true })
  artisanProfileId: string;

  @Prop({ required: true })
  title: string;

  @Prop()
  description: string;

  @Prop()
  priceFcfa: number;

  @Prop({ type: [String] })
  imageUrls: string[];

  @Prop({ type: [String], index: true })
  tags: string[];

  @Prop({ type: Object })
  metadata: Record<string, any>;
}

export const PortfolioItemSchema = SchemaFactory.createForClass(PortfolioItem);
