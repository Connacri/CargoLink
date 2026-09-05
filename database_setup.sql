-- ============================================================================
-- CARGOLINK DATABASE INITIALIZATION
-- ============================================================================
-- Run this script in your Supabase SQL Editor to set up all tables

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  profile_picture_url TEXT,
  role VARCHAR(50) NOT NULL CHECK (role IN ('client', 'shipper', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================================================
-- SHIPPERS TABLE (Micro-importateurs)
-- ============================================================================
CREATE TABLE IF NOT EXISTS shippers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  passport_number VARCHAR(50) NOT NULL UNIQUE,
  passport_photo_url TEXT NOT NULL,
  live_photo_url TEXT NOT NULL,
  verification_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  rejection_reason TEXT,
  verified_by_admin_id UUID REFERENCES users(id) ON DELETE SET NULL,
  verified_at TIMESTAMP WITH TIME ZONE,
  rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
  total_shipments INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_shippers_verification_status ON shippers(verification_status);
CREATE INDEX idx_shippers_rating ON shippers(rating);
CREATE INDEX idx_shippers_user_id ON shippers(user_id);

-- ============================================================================
-- SHIPMENTS TABLE (Offres de transport)
-- ============================================================================
CREATE TABLE IF NOT EXISTS shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipper_id UUID NOT NULL REFERENCES shippers(id) ON DELETE CASCADE,
  origin_country VARCHAR(100) NOT NULL,
  destination_city VARCHAR(100) NOT NULL,
  available_weight_kg DECIMAL(10, 2) NOT NULL CHECK (available_weight_kg > 0),
  reserved_weight_kg DECIMAL(10, 2) NOT NULL DEFAULT 0,
  price_per_kg DECIMAL(10, 2) NOT NULL CHECK (price_per_kg > 0),
  departure_date TIMESTAMP WITH TIME ZONE NOT NULL,
  arrival_date TIMESTAMP WITH TIME ZONE NOT NULL,
  flight_number VARCHAR(50),
  status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shipper_id) REFERENCES shippers(id) ON DELETE CASCADE
);

CREATE INDEX idx_shipments_shipper_id ON shipments(shipper_id);
CREATE INDEX idx_shipments_status ON shipments(status);
CREATE INDEX idx_shipments_destination ON shipments(destination_city);
CREATE INDEX idx_shipments_arrival ON shipments(arrival_date);

-- ============================================================================
-- BOOKINGS TABLE (Réservations des clients)
-- ============================================================================
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id UUID NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_name VARCHAR(255) NOT NULL,
  product_description TEXT NOT NULL,
  product_photos_url TEXT[] DEFAULT ARRAY[]::TEXT[],
  requested_weight_kg DECIMAL(10, 2) NOT NULL CHECK (requested_weight_kg > 0),
  allocated_weight_kg DECIMAL(10, 2) NOT NULL CHECK (allocated_weight_kg > 0),
  total_price DECIMAL(12, 2) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'collected', 'verifying', 'accepted', 'shipped', 'arrived', 'out_for_delivery', 'delivered', 'cancelled')),
  verification_status VARCHAR(50) NOT NULL DEFAULT 'none' CHECK (verification_status IN ('none', 'awaiting_verification', 'verifying', 'accepted', 'returned', 'waiting_client_update')),
  payment_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  delivery_photo_url TEXT,
  receipt_photo_url TEXT,
  receipt_confirmed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shipment_id) REFERENCES shipments(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_bookings_shipment_id ON bookings(shipment_id);
CREATE INDEX idx_bookings_client_id ON bookings(client_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_payment_status ON bookings(payment_status);

-- ============================================================================
-- SHIPMENT TRACKING TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS shipment_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  status VARCHAR(50) NOT NULL CHECK (status IN ('order_processed', 'collected', 'verified', 'verification_returned', 'departed_origin', 'in_transit', 'arrived_destination', 'customs_cleared', 'out_for_delivery', 'delivered', 'cancelled')),
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes TEXT,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

CREATE INDEX idx_tracking_booking_id ON shipment_tracking(booking_id);
CREATE INDEX idx_tracking_status ON shipment_tracking(status);
CREATE INDEX idx_tracking_timestamp ON shipment_tracking(timestamp);

-- ============================================================================
-- DISPUTES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  reported_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('fraud', 'customs_seizure', 'damage', 'non_delivery', 'other')),
  description TEXT NOT NULL,
  evidence_photos_url TEXT[] DEFAULT ARRAY[]::TEXT[],
  status VARCHAR(50) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'rejected')),
  resolution TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  FOREIGN KEY (reported_by_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_disputes_booking_id ON disputes(booking_id);
CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_type ON disputes(type);

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(100) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  related_booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- ============================================================================
-- PAYMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'DZD',
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  payment_method VARCHAR(50),
  transaction_id VARCHAR(255) UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);

-- ============================================================================
-- SHIPPER FLAGS TABLE (for fraud detection)
-- ============================================================================
CREATE TABLE IF NOT EXISTS shipper_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shipper_id UUID NOT NULL REFERENCES shippers(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (shipper_id) REFERENCES shippers(id) ON DELETE CASCADE
);

CREATE INDEX idx_shipper_flags_shipper_id ON shipper_flags(shipper_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shippers ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipment_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Users: Can view own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Shippers: Can view verified shippers
CREATE POLICY "Everyone can view verified shippers"
  ON shippers FOR SELECT
  USING (verification_status = 'verified');

CREATE POLICY "Shippers can view own profile"
  ON shippers FOR SELECT
  USING (auth.uid() = user_id);

-- Shipments: Can view active shipments
CREATE POLICY "Everyone can view active shipments"
  ON shipments FOR SELECT
  USING (status = 'active');

CREATE POLICY "Shippers can manage own shipments"
  ON shipments FOR ALL
  USING (shipper_id IN (SELECT id FROM shippers WHERE user_id = auth.uid()));

-- Bookings: Can view own bookings
CREATE POLICY "Clients can view own bookings"
  ON bookings FOR SELECT
  USING (client_id = auth.uid());

CREATE POLICY "Shippers can view bookings for their shipments"
  ON bookings FOR SELECT
  USING (shipment_id IN (
    SELECT id FROM shipments 
    WHERE shipper_id IN (SELECT id FROM shippers WHERE user_id = auth.uid())
  ));

-- Tracking: Can view own tracking
CREATE POLICY "Users can view tracking for own bookings"
  ON shipment_tracking FOR SELECT
  USING (booking_id IN (
    SELECT id FROM bookings WHERE client_id = auth.uid()
  ) OR booking_id IN (
    SELECT b.id FROM bookings b
    JOIN shipments s ON b.shipment_id = s.id
    WHERE s.shipper_id IN (SELECT id FROM shippers WHERE user_id = auth.uid())
  ));

-- Disputes: Can view own disputes
CREATE POLICY "Users can view own disputes"
  ON disputes FOR SELECT
  USING (
    reported_by_user_id = auth.uid() OR
    booking_id IN (SELECT id FROM bookings WHERE client_id = auth.uid()) OR
    booking_id IN (
      SELECT b.id FROM bookings b
      JOIN shipments s ON b.shipment_id = s.id
      WHERE s.shipper_id IN (SELECT id FROM shippers WHERE user_id = auth.uid())
    )
  );

-- Admin can view all disputes
CREATE POLICY "Admin can manage disputes"
  ON disputes FOR ALL
  USING ((SELECT role FROM users WHERE id = auth.uid()) = 'admin');

-- Notifications: Can view own
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- Payments: Can view own
CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  USING (booking_id IN (SELECT id FROM bookings WHERE client_id = auth.uid()));

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update shipment reserved weight when booking is created
CREATE OR REPLACE FUNCTION update_shipment_reserved_weight()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE shipments
  SET reserved_weight_kg = reserved_weight_kg + NEW.allocated_weight_kg
  WHERE id = NEW.shipment_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reserved_weight
AFTER INSERT ON bookings
FOR EACH ROW
EXECUTE FUNCTION update_shipment_reserved_weight();

-- Function to update shipper stats
CREATE OR REPLACE FUNCTION update_shipper_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE shippers
  SET total_shipments = (SELECT COUNT(*) FROM shipments WHERE shipper_id = NEW.shipper_id)
  WHERE id = NEW.shipper_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_shipper_stats
AFTER INSERT ON shipments
FOR EACH ROW
EXECUTE FUNCTION update_shipper_stats();

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Insert storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('profiles', 'profiles', true),
  ('documents', 'documents', true),
  ('bookings', 'bookings', true)
ON CONFLICT DO NOTHING;

-- Storage policies for public access
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id IN ('profiles', 'documents', 'bookings'));

CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================================
-- INITIAL DATA (optional test data)
-- ============================================================================

-- You can add initial test users/data here if needed
-- INSERT INTO users (email, phone, full_name, role)
-- VALUES ('test@cargolink.com', '+213700000000', 'Test User', 'client');

COMMIT;
