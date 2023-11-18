from typing import List, Dict
import os
from cert_utils import build_subj_str
from user_info import UserInfo

CADatabaseRaw = List[Dict[str, str]]

class CADatabase:
    """
    See: https://pki-tutorial.readthedocs.io/en/latest/cadb.html
    E.g.
    V	241117110612Z		04	unknown	/C=CH/ST=Zurich/O=iMovies/CN=DBPdJyXvGC Bruegger/emailAddress=lb@imovies.ch

    is stored as
    {"status": "V", "expiration_date": "241117110612Z", "revocation_date": "", 
    "serial_number": "04", "certificate_filename": "unknown",
    "distinguished_name": "/C=CH/ST=Zurich/O=iMovies/CN=DBPdJyXvGC Bruegger/emailAddress=lb@imovies.ch"
    }
    """
    def __init__(self, ca_db_path: str) -> None:
        self.raw_db = CADatabase.read_ca_database(ca_db_path)

    def get_serial_numbers(self, user_info: UserInfo, valid_only: bool) -> List[str]:
        """
        Retrieve a list of serial numbers from the certificate database based on user information.

        Args:
            user_info (UserInfo): User information used to identify the certificate.
            valid_only (bool): If True, only consider valid certificates (status "V").

        Returns:
            List[str]: A list of serial numbers corresponding to the matching certificates.

        Note:
            The function searches the certificate database for entries with the provided user information.
            If 'valid_only' is set to True, only valid certificates are considered.
        """
        numbers = []
        subj_str = build_subj_str(user_info)
        for entry in self.raw_db:
            if valid_only and entry['status'] != "V":
                continue

            if entry['distinguished_name'] == subj_str:
                numbers.append(entry['serial_number'])
        return numbers

    def nb_certs_issued(self) -> int:
        return len(self.raw_db)
    
    def nb_certs_revoked(self) -> int:
        return len(list(filter(lambda entry: entry['status'] == 'R', self.raw_db)))

    @staticmethod
    def read_ca_database(ca_db_path: str) -> CADatabaseRaw:
        """
        Reads and parse the database given as argument
        """
        assert os.path.exists(ca_db_path), ca_db_path

        ca_db = []
        with open(ca_db_path, "r") as ca_db_file:
            for raw_entry in ca_db_file:
                cols = raw_entry.strip().split('\t')
                entry = {}
                entry['status'] = cols[0]
                entry['expiration_date'] = cols[1]
                entry['revocation_date'] = cols[2]
                entry['serial_number'] = cols[3]
                entry['certificate_filename'] = cols[4]
                entry['distinguished_name'] = cols[5]

                ca_db.append(entry)
        return ca_db