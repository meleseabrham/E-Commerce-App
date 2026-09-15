-- ========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES (CLEAN VERSION)
-- ========================================================

-- General setup: Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;

-- Helper function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND (is_admin = true OR role = 'admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- USERS
-- ========================================
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.users;
DROP POLICY IF EXISTS "Authenticated users can read admin profiles" ON public.users;

CREATE POLICY "Users can read own profile" ON public.users
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Admins can read all profiles" ON public.users
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Authenticated users can read admin profiles" ON public.users
  FOR SELECT TO authenticated USING (is_admin = true OR role = 'admin');

-- ========================================
-- USER_ADDRESSES
-- ========================================
DROP POLICY IF EXISTS "Users can manage own addresses" ON public.user_addresses;

CREATE POLICY "Users can manage own addresses" ON public.user_addresses
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- CATEGORIES
-- ========================================
DROP POLICY IF EXISTS "Public can read categories" ON public.categories;
DROP POLICY IF EXISTS "Public read categories" ON public.categories;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.categories;
DROP POLICY IF EXISTS "Admins manage categories" ON public.categories;
DROP POLICY IF EXISTS "Auth can write categories (dev)" ON public.categories;

CREATE POLICY "Public read categories" ON public.categories
  FOR SELECT TO public USING (true);

CREATE POLICY "Admins manage categories" ON public.categories
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ========================================
-- PRODUCTS
-- ========================================
DROP POLICY IF EXISTS "Public can read products" ON public.products;
DROP POLICY IF EXISTS "Public read products" ON public.products;
DROP POLICY IF EXISTS "Public read access" ON public.products;
DROP POLICY IF EXISTS "Authenticated can insert products" ON public.products;
DROP POLICY IF EXISTS "Authenticated insert products" ON public.products;
DROP POLICY IF EXISTS "Authenticated can update products" ON public.products;
DROP POLICY IF EXISTS "Authenticated update products" ON public.products;
DROP POLICY IF EXISTS "Authenticated delete products" ON public.products;
DROP POLICY IF EXISTS "Authenticated upload products" ON public.products;
DROP POLICY IF EXISTS "Enable insert for users based on user_id" ON public.products;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.products;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.products;
DROP POLICY IF EXISTS "Admins manage products" ON public.products;

CREATE POLICY "Public read products" ON public.products
  FOR SELECT TO public USING (true);

CREATE POLICY "Admins manage products" ON public.products
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ========================================
-- PRODUCT_REVIEWS
-- ========================================
DROP POLICY IF EXISTS "Public can read reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Public read product reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Users can insert reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Authenticated insert reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Authenticated update own review" ON public.product_reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON public.product_reviews;
DROP POLICY IF EXISTS "Authenticated delete own review" ON public.product_reviews;
DROP POLICY IF EXISTS "Users can manage own reviews" ON public.product_reviews;

CREATE POLICY "Public read reviews" ON public.product_reviews
  FOR SELECT TO public USING (true);

CREATE POLICY "Users can manage own reviews" ON public.product_reviews
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- WISHLIST
-- ========================================
DROP POLICY IF EXISTS "Users can manage their own wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Public read wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Authenticated insert wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Authenticated delete wishlist" ON public.wishlist;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.wishlist;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.wishlist;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.wishlist;
DROP POLICY IF EXISTS "Users can manage own wishlist" ON public.wishlist;

CREATE POLICY "Users can manage own wishlist" ON public.wishlist
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- ORDERS
-- ========================================
DROP POLICY IF EXISTS "Users can see their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated insert orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated read own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can read own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can insert own orders" ON public.orders;
DROP POLICY IF EXISTS "Admins can view all orders" ON public.orders;

CREATE POLICY "Users can read own orders" ON public.orders
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own orders" ON public.orders
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all orders" ON public.orders
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- ========================================
-- ORDER_ITEMS
-- ========================================
DROP POLICY IF EXISTS "Users can see order items of their orders" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON public.order_items;
DROP POLICY IF EXISTS "Authenticated read own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can read own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can insert order items for own orders" ON public.order_items;

CREATE POLICY "Users can read own order items" ON public.order_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert order items for own orders" ON public.order_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- ========================================
-- PAYMENTS
-- ========================================
DROP POLICY IF EXISTS "Users can see their own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can insert payments" ON public.payments;
DROP POLICY IF EXISTS "Authenticated insert payments" ON public.payments;
DROP POLICY IF EXISTS "Authenticated read own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can read own payments" ON public.payments;
DROP POLICY IF EXISTS "Users can insert own payments" ON public.payments;

CREATE POLICY "Users can read own payments" ON public.payments
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments" ON public.payments
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- NOTIFICATIONS
-- ========================================
DROP POLICY IF EXISTS "Admins can view all notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can read notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins read notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can manage notifications" ON public.notifications;

CREATE POLICY "Users can read own notifications" ON public.notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage notifications" ON public.notifications
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ========================================
-- AUDIT_LOGS
-- ========================================
DROP POLICY IF EXISTS "Admins can read audit logs" ON public.audit_logs;

CREATE POLICY "Admins can read audit logs" ON public.audit_logs
  FOR SELECT TO authenticated
  USING (public.is_admin());

-- ========================================
-- CARTS
-- ========================================
DROP POLICY IF EXISTS "Users can manage own cart" ON public.carts;

CREATE POLICY "Users can manage own cart" ON public.carts
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- STORAGE (BUCKETS & OBJECTS)
-- ========================================

-- AVATARS' STORAGE POLICIES
DROP POLICY IF EXISTS "Upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Delete own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;

CREATE POLICY "Upload own avatar"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY "Update own avatar"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY "Delete own avatar"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND owner = auth.uid());

CREATE POLICY "Public read avatars"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

-- PRODUCT-IMAGES' STORAGE POLICIES
DROP POLICY IF EXISTS "Authenticated upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated read product images" ON storage.objects;
DROP POLICY IF EXISTS "Public read product images" ON storage.objects;
DROP POLICY IF EXISTS "Admins manage product images" ON storage.objects;

CREATE POLICY "Public read product images"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'product-images');

CREATE POLICY "Admins manage product images"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'product-images' AND public.is_admin())
  WITH CHECK (bucket_id = 'product-images' AND public.is_admin());