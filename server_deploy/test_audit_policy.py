import unittest

import audit_policy


class RconAuditPolicyTests(unittest.TestCase):
    def test_poppolouse_is_exempt_case_insensitively(self):
        for username in ("Poppolouse", "poppolouse", " POPPOLOUSE "):
            with self.subTest(username=username):
                self.assertFalse(audit_policy.should_log_rcon(username))

    def test_other_users_are_still_logged(self):
        self.assertTrue(audit_policy.should_log_rcon("another-admin"))


if __name__ == "__main__":
    unittest.main()
