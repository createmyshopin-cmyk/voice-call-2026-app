import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';

export interface WithdrawalRequest {
  id: string;
  listenerId: string;
  listenerName: string;
  amount: number;
  upiId?: string;
  bankDetails?: {
    bankName: string;
    accountNo: string;
    ifsc: string;
    holderName: string;
  };
  requestDate: string;
  status: 'pending' | 'approved' | 'paid' | 'rejected';
}

@Injectable()
export class WithdrawalsService {
  private requests: WithdrawalRequest[] = [
    { id: 'WDR001', listenerId: 'LIS001', listenerName: 'Ishita Sen (RJ)', amount: 5000, upiId: 'ishita@okaxis', requestDate: '2026-06-02T10:00:00Z', status: 'pending' },
    { id: 'WDR002', listenerId: 'LIS003', listenerName: 'Sneha Rao', amount: 8000, upiId: 'snehar@paytm', requestDate: '2026-06-01T15:30:00Z', status: 'approved' },
    { id: 'WDR003', listenerId: 'LIS002', listenerName: 'Karan Malhotra', amount: 3000, bankDetails: { bankName: 'SBI', accountNo: '30245678901', ifsc: 'SBIN0000690', holderName: 'Karan Malhotra' }, requestDate: '2026-05-28T11:00:00Z', status: 'paid' }
  ];

  async getRequests() {
    return this.requests;
  }

  async findOne(id: string) {
    const request = this.requests.find(r => r.id === id);
    if (!request) {
      throw new NotFoundException(`Withdrawal request with ID ${id} not found`);
    }
    return request;
  }

  async updateStatus(id: string, status: 'approved' | 'paid' | 'rejected') {
    const request = await this.findOne(id);
    
    if (request.status === 'paid' || request.status === 'rejected') {
      throw new BadRequestException(`Cannot alter withdrawal request which is already ${request.status}`);
    }

    if (status === 'paid' && request.status !== 'approved') {
      throw new BadRequestException('Can only mark as paid if the request was previously approved');
    }

    request.status = status;
    return {
      message: `Withdrawal request status updated to ${status}`,
      request
    };
  }
}
