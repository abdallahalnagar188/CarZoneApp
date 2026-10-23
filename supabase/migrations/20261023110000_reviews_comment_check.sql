-- Allow both localized JSON object and string for reviews.comment
ALTER TABLE public.reviews DROP CONSTRAINT IF EXISTS reviews_comment_check;
ALTER TABLE public.reviews ADD CONSTRAINT reviews_comment_check CHECK (jsonb_typeof(comment) IN ('object', 'string'));
