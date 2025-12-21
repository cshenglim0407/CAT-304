-- 1. Create the function to handle the data transfer
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  normalized_gender TEXT;
  normalized_dob DATE;
  display_name TEXT;
BEGIN
  normalized_dob := NULLIF(NEW.raw_user_meta_data->>'date_of_birth','')::date;

  normalized_gender := NULLIF(NEW.raw_user_meta_data->>'gender','');
  IF normalized_gender IS NOT NULL THEN
    normalized_gender := UPPER(normalized_gender);
    IF normalized_gender NOT IN ('MALE', 'FEMALE', 'OTHER') THEN
      RAISE EXCEPTION 'Invalid gender value: %', normalized_gender;
    END IF;
  END IF;

  display_name := COALESCE(
    NULLIF(NEW.raw_user_meta_data->>'display_name', ''),
    NULLIF(NEW.raw_user_meta_data->>'name', '')
  );

  INSERT INTO public.app_users (user_id, email, date_of_birth, gender, display_name)
  VALUES (NEW.id, NEW.email, normalized_dob, normalized_gender, display_name);

  RETURN NEW;
END;
$$;

-- 2. Create the trigger
DROP TRIGGER IF EXISTS trg_handle_new_user ON auth.users;

CREATE TRIGGER trg_handle_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();