import { Controller, Get, Post, Body, Param, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreatePackageDto, VerifyPaymentDto } from './dto/payment.dto';
import { JwtAuthGuard } from '../auth/auth.guard';
import { AdminGuard } from '../auth/admin.guard';

@ApiTags('Recharges & Coin Packages')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Get('packages')
  @ApiOperation({ summary: 'Get available coin packages' })
  @ApiResponse({ status: 200, description: 'List of coin packages.' })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  getPackages() {
    return this.paymentsService.getPackages();
  }

  @Post('packages')
  @UseGuards(AdminGuard)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create new coin package (admin)' })
  @ApiResponse({ status: 201, description: 'Package created.' })
  @ApiResponse({ status: 403, description: 'Admin access required.' })
  createPackage(@Body() createPackageDto: CreatePackageDto) {
    return this.paymentsService.createPackage(createPackageDto);
  }

  @Get('history')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Get recharge transaction history (admin)' })
  @ApiResponse({ status: 200, description: 'List of payment logs.' })
  @ApiResponse({ status: 403, description: 'Admin access required.' })
  getPayments() {
    return this.paymentsService.getPayments();
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify pending recharge payment' })
  @ApiResponse({ status: 200, description: 'Payment verified and credited.' })
  @ApiResponse({ status: 401, description: 'Unauthorized.' })
  verify(@Body() verifyPaymentDto: VerifyPaymentDto) {
    return this.paymentsService.verifyPayment(verifyPaymentDto);
  }

  @Post(':paymentId/refund')
  @UseGuards(AdminGuard)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refund a successful recharge (admin)' })
  @ApiResponse({ status: 200, description: 'Payment refunded and coins reversed.' })
  @ApiResponse({ status: 403, description: 'Admin access required.' })
  refund(
    @Param('paymentId') paymentId: string,
    @Body('reason') reason?: string,
  ) {
    return this.paymentsService.refundPayment(paymentId, reason);
  }
}
