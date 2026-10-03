import { Company, CompanyMember, Driver, User } from '@prisma/client';

export interface RequestContext {
  user: User;
  driver: Driver | null;
  companyMember: (CompanyMember & { company: Company }) | null;
}

declare module 'express' {
  interface Request {
    authContext?: RequestContext;
  }
}
