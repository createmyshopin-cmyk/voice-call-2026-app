import { Controller, Get, Post, Param, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { WithdrawalsService } from './withdrawals.service';
import { JwtAuthGuard } from '../auth/auth.guard';
import { AdminGuard } from '../auth/admin.guard';

@ApiTags('Withdrawals & Payout Requests')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AdminGuard)
@Controller('withdrawals')
export class WithdrawalsController {
  constructor(private readonly withdrawalsService: WithdrawalsService) {}

  @Get('requests')
  @ApiOperation({ summary: 'Get all payout/withdrawal requests' })
  @ApiResponse({ status: 200, description: 'List of requests.' })
  @ApiResponse({ status: 403, description: 'Admin access required.' })
  getRequests() {
    return this.withdrawalsService.getRequests();
  }

  @Post(':id/approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Approve payout request' })
  approve(@Param('id') id: string) {
    return this.withdrawalsService.updateStatus(id, 'approved');
  }

  @Post(':id/pay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark payout request as processed/paid' })
  pay(@Param('id') id: string) {
    return this.withdrawalsService.updateStatus(id, 'paid');
  }

  @Post(':id/reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reject payout request' })
  reject(@Param('id') id: string) {
    return this.withdrawalsService.updateStatus(id, 'rejected');
  }
}
