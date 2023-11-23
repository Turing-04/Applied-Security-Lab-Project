from backup_utils import pgp_encrypt
from pgpy import PGPMessage

def test_gpg_encrypt():
    test_data = "My nice test data"
    plaintext = str(PGPMessage.new(test_data))
    ciphertext = pgp_encrypt(test_data)
    assert ciphertext != ""
    assert ciphertext != test_data
    assert plaintext != ciphertext
    print(plaintext, ciphertext)