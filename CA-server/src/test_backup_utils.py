from backup_utils import pgp_encrypt
from pgpy import PGPMessage

def test_gpg_encrypt():
    with open('./test_data/test_cert_key.p12', 'rb') as test_p12:
        test_data = test_p12.read()
        plaintext = str(PGPMessage.new(test_data))
        ciphertext = pgp_encrypt(test_data)
        assert ciphertext != ""
        assert ciphertext != test_data
        assert plaintext != ciphertext
        print(plaintext, ciphertext)