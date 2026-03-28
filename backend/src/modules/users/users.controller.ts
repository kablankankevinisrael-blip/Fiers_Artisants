import {
  Controller,
  Get,
  Put,
  Param,
  Body,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { UsersService } from './users.service';
import { UpdateArtisanProfileDto } from './dto/update-artisan-profile.dto';
import { UpdateClientProfileDto } from './dto/update-client-profile.dto';
import { CurrentUser } from '../../common/decorators';
import { RolesGuard } from '../../common/guards';
import { Roles } from '../../common/decorators';

@Controller()
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // ── Artisan Profile ─────────────────────────────────────────────
  @Get('artisan/profile')
  @UseGuards(RolesGuard)
  @Roles('ARTISAN')
  getMyArtisanProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getArtisanProfile(userId);
  }

  @Put('artisan/profile')
  @UseGuards(RolesGuard)
  @Roles('ARTISAN')
  updateMyArtisanProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateArtisanProfileDto,
  ) {
    return this.usersService.updateArtisanProfile(userId, dto);
  }

  @Get('artisan/:id')
  getArtisanPublicProfile(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.getArtisanPublicProfile(id);
  }

  // ── Client Profile ──────────────────────────────────────────────
  @Get('client/profile')
  @UseGuards(RolesGuard)
  @Roles('CLIENT')
  getMyClientProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getClientProfile(userId);
  }

  @Put('client/profile')
  @UseGuards(RolesGuard)
  @Roles('CLIENT')
  updateMyClientProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateClientProfileDto,
  ) {
    return this.usersService.updateClientProfile(userId, dto);
  }
}
