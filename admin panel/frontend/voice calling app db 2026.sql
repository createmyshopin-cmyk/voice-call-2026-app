CREATE TABLE "users" (
  "id" uuid PRIMARY KEY,
  "firebase_uid" varchar UNIQUE,
  "name" varchar,
  "username" varchar UNIQUE,
  "email" varchar,
  "phone" varchar,
  "profile_image" text,
  "gender" varchar,
  "country" varchar,
  "is_creator" boolean DEFAULT false,
  "is_verified" boolean DEFAULT false,
  "status" varchar DEFAULT 'active',
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "creator_profiles" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid UNIQUE,
  "bio" text,
  "languages" varchar,
  "experience" varchar,
  "price_per_minute" integer,
  "rating" decimal,
  "total_calls" integer,
  "total_minutes" integer,
  "total_earnings" integer,
  "online_status" boolean,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "wallets" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid UNIQUE,
  "coin_balance" integer,
  "created_at" timestamp,
  "updated_at" timestamp
);

CREATE TABLE "coin_packages" (
  "id" uuid PRIMARY KEY,
  "name" varchar,
  "coins" integer,
  "bonus_coins" integer,
  "price" decimal,
  "is_active" boolean,
  "created_at" timestamp
);

CREATE TABLE "payments" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid,
  "package_id" uuid,
  "gateway" varchar,
  "gateway_order_id" varchar,
  "amount" decimal,
  "coins_added" integer,
  "status" varchar,
  "created_at" timestamp
);

CREATE TABLE "transactions" (
  "id" uuid PRIMARY KEY,
  "user_id" uuid,
  "type" varchar,
  "amount" integer,
  "balance_before" integer,
  "balance_after" integer,
  "reference_id" uuid,
  "description" text,
  "status" varchar,
  "created_at" timestamp
);

CREATE TABLE "call_requests" (
  "id" uuid PRIMARY KEY,
  "caller_id" uuid,
  "receiver_id" uuid,
  "call_type" varchar,
  "status" varchar,
  "created_at" timestamp
);

CREATE TABLE "calls" (
  "id" uuid PRIMARY KEY,
  "caller_id" uuid,
  "receiver_id" uuid,
  "call_request_id" uuid,
  "agora_channel" varchar,
  "call_type" varchar,
  "started_at" timestamp,
  "ended_at" timestamp,
  "duration_seconds" integer,
  "creator_rate" integer,
  "coins_charged" integer,
  "creator_earning" integer,
  "status" varchar,
  "created_at" timestamp
);

CREATE TABLE "creator_wallets" (
  "id" uuid PRIMARY KEY,
  "creator_id" uuid UNIQUE,
  "total_earned" integer,
  "available_balance" integer,
  "withdrawn_amount" integer,
  "updated_at" timestamp
);

CREATE TABLE "withdrawals" (
  "id" uuid PRIMARY KEY,
  "creator_id" uuid,
  "amount" integer,
  "account_name" varchar,
  "bank_name" varchar,
  "account_number" varchar,
  "ifsc_code" varchar,
  "status" varchar,
  "admin_note" text,
  "created_at" timestamp
);

CREATE TABLE "app_settings" (
  "id" uuid PRIMARY KEY,
  "coin_to_rupee_ratio" decimal,
  "platform_commission_percent" decimal,
  "min_withdrawal" integer,
  "updated_at" timestamp
);

ALTER TABLE "creator_profiles" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "wallets" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payments" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payments" ADD FOREIGN KEY ("package_id") REFERENCES "coin_packages" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transactions" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "call_requests" ADD FOREIGN KEY ("caller_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "call_requests" ADD FOREIGN KEY ("receiver_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "calls" ADD FOREIGN KEY ("caller_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "calls" ADD FOREIGN KEY ("receiver_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "calls" ADD FOREIGN KEY ("call_request_id") REFERENCES "call_requests" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "creator_wallets" ADD FOREIGN KEY ("creator_id") REFERENCES "creator_profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "withdrawals" ADD FOREIGN KEY ("creator_id") REFERENCES "creator_profiles" ("id") DEFERRABLE INITIALLY IMMEDIATE;
