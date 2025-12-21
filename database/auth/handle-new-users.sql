CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.APP_USERS (
    USER_ID,          -- Matches your table's column name
    DISPLAY_NAME, 
    DATE_OF_BIRTH, 
    GENDER, 
    EMAIL
  )
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'display_name', 
    (new.raw_user_meta_data->>'date_of_birth')::date, 
    UPPER(new.raw_user_meta_data->>'gender'), -- Ensures 'Male' becomes 'MALE'
    new.email
  );
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  -- Prevents sign-up failure if there is a data mismatch
  RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
  RETURN new; 
END;
$$;

-- Re-link the trigger
DROP TRIGGER IF EXISTS trg_handle_new_user ON auth.users;
CREATE TRIGGER trg_handle_new_user
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();