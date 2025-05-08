# PyScript to generate and store a secure hash password
import crypt,getpass,subprocess,sys,os;
password=getpass.getpass('Enter password: ');
hashed_password=crypt.crypt(password,crypt.mksalt(crypt.METHOD_SHA512));
entered=getpass.getpass('Enter password again to verify: ');
if crypt.crypt(entered, hashed_password) == hashed_password:
    password=None
    entered=None
    print("Passwords match!")
else:
    print("Passwords do not match.")
    entered=None
    password=None
    sys.exit(1)
output_path = os.path.join(os.getcwd(), ".myhash")
with open(output_path, "w") as file:
    file.write(hashed_password)
print(f"Hashed Password saved to: {output_path}")
