{fetchurl, buildPerlPackage, DBI, mysql}:

buildPerlPackage {
  name = "DBD-mysql-4.023";

  src = fetchurl {
    url = mirror://cpan/authors/id/C/CA/CAPTTOFU/DBD-mysql-4.023.tar.gz;
    sha256 = "0j4i0i6apjwx5klk3wigh6yysssn7bs6p8c5sh31m6qxsbgyk9xa";
  };

  # WARNING: If you have mysql running the tests fail!
  # DBD::mysql::db do failed: alter routine command denied to user ''@'localhost' for routine 'test.testproc' at t/80procs.t line 41.
  #doCheck = false;

  buildInputs = [mysql] ;
  propagatedBuildInputs = [DBI];

#  makeMakerFlags = "MYSQL_HOME=${mysql}";
}
