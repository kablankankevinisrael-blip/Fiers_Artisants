import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PortfolioService } from './portfolio.service';
import { CurrentUser, Roles } from '../../common/decorators';
import { RolesGuard } from '../../common/guards';

@Controller('portfolio')
@UseGuards(AuthGuard('jwt'), RolesGuard)
@Roles('ARTISAN')
export class PortfolioController {
  constructor(private readonly portfolioService: PortfolioService) {}

  @Get()
  findMyItems(@CurrentUser('id') userId: string) {
    return this.portfolioService.findMyItems(userId);
  }

  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: any) {
    return this.portfolioService.create(userId, dto);
  }

  @Put(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: any,
  ) {
    return this.portfolioService.update(userId, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.portfolioService.remove(userId, id);
  }
}

@Controller('artisan')
export class ArtisanPortfolioController {
  constructor(private readonly portfolioService: PortfolioService) {}

  @Get(':id/portfolio')
  findByArtisan(@Param('id') id: string) {
    return this.portfolioService.findByArtisan(id);
  }
}
