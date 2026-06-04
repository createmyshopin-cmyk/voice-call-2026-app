import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { CoinTransactionsService } from '../calls/coin-transactions.service';
import { CreatePackageDto, VerifyPaymentDto } from './dto/payment.dto';

export interface CoinPackage {
  id: string;
  name: string;
  coins: number;
  bonusCoins: number;
  price: number;
  enabled: boolean;
}

export interface PaymentRecord {
  id: string;
  userId: string;
  userName: string;
  amount: number;
  coins: number;
  gateway: string;
  transactionId: string;
  status: 'success' | 'failed' | 'pending';
  date: string;
}

@Injectable()
export class PaymentsService {
  constructor(
    private readonly usersService: UsersService,
    private readonly coinTransactions: CoinTransactionsService,
  ) {}

  private packages: CoinPackage[] = [
    { id: 'PKG001', name: 'Starter Pack', coins: 100, bonusCoins: 0, price: 99, enabled: true },
    { id: 'PKG002', name: 'Value Pack', coins: 500, bonusCoins: 50, price: 399, enabled: true },
    { id: 'PKG003', name: 'Popular Pack', coins: 1000, bonusCoins: 150, price: 699, enabled: true }
  ];

  private payments: PaymentRecord[] = [
    { id: 'PAY001', userId: 'USR001', userName: 'Aarav Sharma', amount: 399, coins: 550, gateway: 'Razorpay', transactionId: 'pay_Nz82Bcx90P', status: 'success', date: '2026-06-03T18:00:00Z' },
    { id: 'PAY002', userId: 'USR003', userName: 'Priya Patel', amount: 699, coins: 1150, gateway: 'Razorpay', transactionId: 'pay_Oz93Ccx91Q', status: 'success', date: '2026-06-02T12:00:00Z' },
    { id: 'PAY003', userId: 'USR002', userName: 'Rohan Mehta', amount: 99, coins: 100, gateway: 'UPI', transactionId: 'upi_230918239', status: 'failed', date: '2026-06-03T19:00:00Z' },
    { id: 'PAY004', userId: 'USR001', userName: 'Aarav Sharma', amount: 399, coins: 550, gateway: 'Razorpay', transactionId: 'pay_pending_123', status: 'pending', date: '2026-06-03T21:00:00Z' }
  ];

  async getPackages() {
    return this.packages.filter(p => p.enabled);
  }

  async createPackage(dto: CreatePackageDto) {
    const pkg: CoinPackage = {
      id: `PKG${Date.now().toString().slice(-4)}`,
      name: dto.name,
      coins: dto.coins,
      bonusCoins: dto.bonusCoins,
      price: dto.price,
      enabled: true
    };
    this.packages.push(pkg);
    return pkg;
  }

  async getPayments() {
    return this.payments;
  }

  async verifyPayment(dto: VerifyPaymentDto) {
    const payment = this.payments.find(p => p.id === dto.paymentId);
    if (!payment) {
      throw new NotFoundException(`Payment record ${dto.paymentId} not found`);
    }

    if (payment.status !== 'pending') {
      throw new BadRequestException('Payment has already been processed');
    }

    payment.transactionId = dto.transactionId;
    payment.status = 'success';

    const user = await this.usersService.findOne(payment.userId);
    const balanceBefore = user.coins;
    const updatedUser = await this.usersService.updateCoins(payment.userId, payment.coins);

    await this.coinTransactions.recordRecharge({
      userId: payment.userId,
      coinsAdded: payment.coins,
      balanceBefore,
      balanceAfter: updatedUser.coins,
      paymentId: payment.id,
      gateway: payment.gateway,
    });

    return {
      message: 'Payment verified and coins credited successfully',
      payment
    };
  }

  async refundPayment(paymentId: string, reason?: string) {
    const payment = this.payments.find(p => p.id === paymentId);
    if (!payment) {
      throw new NotFoundException(`Payment record ${paymentId} not found`);
    }

    if (payment.status !== 'success') {
      throw new BadRequestException('Only successful payments can be refunded');
    }

    const user = await this.usersService.findOne(payment.userId);
    const balanceBefore = user.coins;
    const updatedUser = await this.usersService.updateCoins(payment.userId, -payment.coins);

    await this.coinTransactions.recordRefund({
      userId: payment.userId,
      coinsRefunded: payment.coins,
      balanceBefore,
      balanceAfter: updatedUser.coins,
      referenceId: payment.id,
      reason: reason ?? `Refund for payment ${payment.id}`,
    });

    payment.status = 'failed';

    return {
      message: 'Payment refunded and coins deducted',
      payment,
    };
  }
}
