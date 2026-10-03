import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Review } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  toDto(review: Review) {
    return {
      id: review.id,
      dealId: review.dealId,
      authorUserId: review.authorUserId,
      authorRole: review.authorRole,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
    };
  }

  async forDeal(dealId: string) {
    const reviews = await this.prisma.review.findMany({ where: { dealId } });
    return reviews.map((r) => this.toDto(r));
  }

  async submit(dealId: string, authorUserId: string, authorRole: 'DRIVER' | 'COMPANY', rating: number, comment?: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id: dealId } });
    if (!deal) throw new NotFoundException('Deal not found');
    if (deal.status !== 'DELIVERED') {
      throw new BadRequestException('Reviews are only allowed for delivered deals');
    }

    const existing = await this.prisma.review.findUnique({
      where: { dealId_authorRole: { dealId, authorRole } },
    });
    if (existing) throw new ConflictException('You have already reviewed this deal');

    const review = await this.prisma.review.create({
      data: { dealId, authorUserId, authorRole, rating, comment },
    });
    return this.toDto(review);
  }
}
