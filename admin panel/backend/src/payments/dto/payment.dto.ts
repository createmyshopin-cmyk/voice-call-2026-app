import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString } from 'class-validator';

export class VerifyPaymentDto {
  @ApiProperty({ example: 'PAY001' })
  @IsString()
  @IsNotEmpty()
  paymentId: string;

  @ApiProperty({ example: 'pay_Nz82Bcx90P' })
  @IsString()
  @IsNotEmpty()
  transactionId: string;
}

export class CreatePackageDto {
  @ApiProperty({ example: 'Starter Pack' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 100 })
  @IsNumber()
  coins: number;

  @ApiProperty({ example: 10 })
  @IsNumber()
  bonusCoins: number;

  @ApiProperty({ example: 99 })
  @IsNumber()
  price: number;
}
