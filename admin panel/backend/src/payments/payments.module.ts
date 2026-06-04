import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { CoinPackagesController } from './coin-packages.controller';
import { UsersModule } from '../users/users.module';
import { CoinTransactionsModule } from '../coin-transactions/coin-transactions.module';

@Module({
  imports: [AuthModule, UsersModule, CoinTransactionsModule],
  controllers: [PaymentsController, CoinPackagesController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
