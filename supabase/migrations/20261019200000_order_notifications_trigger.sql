-- Migration: 20261019200000_order_notifications_trigger.sql
-- Automatically insert customer notifications into customer_notifications table on order status changes

CREATE OR REPLACE FUNCTION public.handle_order_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
  v_type text;
  v_title jsonb;
  v_body jsonb;
  v_notif_id text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_type := 'created';
    v_title := jsonb_build_object('ar', 'تم إنشاء الحجز بنجاح', 'en', 'Booking Created');
    v_body := jsonb_build_object('ar', 'طلبك رقم #' || NEW.number || ' قيد المراجعة في الفرع', 'en', 'Order #' || NEW.number || ' is under review');
  ELSIF TG_OP = 'UPDATE' AND (OLD.status IS DISTINCT FROM NEW.status) THEN
    IF NEW.status = 'confirmed' THEN
      v_type := 'confirmed';
      v_title := jsonb_build_object('ar', 'تم تأكيد الحجز', 'en', 'Booking Confirmed');
      v_body := jsonb_build_object('ar', 'تم تأكيد حجزك رقم #' || NEW.number || ' بنجاح', 'en', 'Your booking #' || NEW.number || ' is confirmed');
    ELSIF NEW.status = 'waiting' THEN
      v_type := 'waiting';
      v_title := jsonb_build_object('ar', 'في قائمة الانتظار', 'en', 'In Queue');
      v_body := jsonb_build_object('ar', 'وصلت سيارتك للفرع وجارٍ تجهيز مسار الغسيل للطلب #' || NEW.number, 'en', 'Your vehicle arrived at the branch for order #' || NEW.number);
    ELSIF NEW.status = 'in_service' THEN
      v_type := 'in_service';
      v_title := jsonb_build_object('ar', 'بدء الخدمة', 'en', 'Washing In Progress');
      v_body := jsonb_build_object('ar', 'بدأ العمل على سيارتك الآن للطلب #' || NEW.number, 'en', 'Work on your vehicle has started for order #' || NEW.number);
    ELSIF NEW.status = 'completed' THEN
      v_type := 'completed';
      v_title := jsonb_build_object('ar', 'سيارتك جاهزة!', 'en', 'Vehicle Ready!');
      v_body := jsonb_build_object('ar', 'اكتملت الخدمة! سيارتك جاهزة للاستلام للطلب #' || NEW.number, 'en', 'Service completed! Your car is ready for pickup for order #' || NEW.number);
    ELSIF NEW.status = 'cancelled' THEN
      v_type := 'cancelled';
      v_title := jsonb_build_object('ar', 'تم إلغاء الحجز', 'en', 'Booking Cancelled');
      v_body := jsonb_build_object('ar', 'تم إلغاء الحجز رقم #' || NEW.number, 'en', 'Booking #' || NEW.number || ' was cancelled');
    ELSE
      RETURN NEW;
    END IF;
  ELSE
    RETURN NEW;
  END IF;

  v_notif_id := 'cn_' || NEW.id || '_' || v_type;

  INSERT INTO public.customer_notifications (
    id, customer_id, type, title, body, href, order_id, read, created_at
  ) VALUES (
    v_notif_id, NEW.customer_id, v_type, v_title, v_body, '/booking_details?id=' || NEW.id, NEW.id, false, now()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_order_status_notification ON public.orders;
CREATE TRIGGER trg_order_status_notification
AFTER INSERT OR UPDATE OF status ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_status_notification();
