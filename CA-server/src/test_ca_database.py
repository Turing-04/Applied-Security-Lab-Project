from ca_database import CADatabase

def test_read_ca_database():
    ca_db = CADatabase('./test_data/index.txt').raw_db

    first = ca_db[0]
    assert first['status'] == 'R'
    assert first['expiration_date'] == '241125161537Z'
    assert first['revocation_date'] == '991125161537Z'

    last = ca_db[-1]
    assert last['revocation_date'] == ''
    assert last['serial_number'] == '11'
    assert last['certificate_filename'] == 'unknown'
    assert last['distinguished_name'] == '/C=CH/ST=Zurich/O=iMovies/UID=lb/CN=YAxcvCBsmA Bruegger/emailAddress=lb.bla@imovies.ch'


def test_get_serial_numbers():
    ca_db = CADatabase('./test_data/index.txt')
    # /C=CH/ST=Zurich/O=iMovies/CN=VfOnrgOgDG Bruegger/emailAddress=lb@imovies.ch
    uid = 'lb'
    valid_serial_nbs = ca_db.get_serial_numbers(uid, valid_only=True)
    assert len(valid_serial_nbs) == 17 - 1 - 2 # 1 revoked, 2 for UID=aa
    assert valid_serial_nbs[0] == '02'

def test_nb_certs_issued_revoked():
    ca_db = CADatabase('./test_data/index.txt')
    assert ca_db.nb_certs_issued() == 17
    assert ca_db.nb_certs_revoked() == 1


if __name__ == '__main__':
    # for debug
    test_get_serial_numbers()