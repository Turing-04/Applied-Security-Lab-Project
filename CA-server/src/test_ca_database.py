from ca_database import CADatabase

def test_read_ca_database():
    ca_db = CADatabase('./test_data/index.txt').raw_db

    first = ca_db[0]
    assert first['status'] == 'R'
    assert first['expiration_date'] == '241117110611Z'
    assert first['revocation_date'] == '231118111002Z'

    last = ca_db[-1]
    assert last['revocation_date'] == ''
    assert last['serial_number'] == '0F'
    assert last['certificate_filename'] == 'unknown'
    assert last['distinguished_name'] == '/C=CH/ST=Zurich/O=iMovies/CN=WTmEgFRuvb Bruegger/emailAddress=lb@imovies.ch'


def test_get_serial_numbers():
    ca_db = CADatabase('./test_data/index.txt')
    # ca_db = CADatabase('./src/test_data/index.txt')
    # /C=CH/ST=Zurich/O=iMovies/CN=VfOnrgOgDG Bruegger/emailAddress=lb@imovies.ch
    user_info = {'uid': 'lb', 'firstname': 'VfOnrgOgDG', 'lastname': 'Bruegger', 'email':'lb@imovies.ch'}
    valid_serial_nbs = ca_db.get_serial_numbers(user_info, valid_only=True)
    assert len(valid_serial_nbs) == 1
    assert valid_serial_nbs[0] == '0C'


if __name__ == '__main__':
    # for debug
    test_get_serial_numbers()