args : with args;
# each attr contains the name deriv referencing the derivation and ini which
# evaluates to a string which can be appended to the global unix odbc ini file
# to register the driver
# I haven't done any parameter tweaking.. So the defaults provided here might be bad
{
# new postgres connector library (doesn't work yet)
  psqlng = rec {
    deriv = stdenv.mkDerivation {
      name = "unix-odbc-pg-odbcng-0.90.101";
      buildInputs = [ unixODBC glibc libtool postgresql ];
      # added -ltdl to resolve missing references `dlsym' `dlerror' `dlopen' `dlclose' 
      preConfigure="
        export CPPFLAGS=-I${unixODBC}/include
        export LDFLAGS='-L${unixODBC}/lib -lltdl'
      ";
      src = fetchurl {
        # using my mirror because original url is https
        # https://projects.commandprompt.com/public/odbcng/attachment/wiki/Downloads/odbcng-0.90.101.tar.gz";
        url = http://mawercer.de/~publicrepos/odbcng-0.90.101.tar.gz;
        sha256 = "13z3sify4z2jcil379704w0knkpflg6di4jh6zx1x2gdgzydxa1y";
      };
      meta = {
          description = "unix odbc driver for postgresql";
          homepage = https://projects.commandprompt.com/public/odbcng;
          license = stdenv.lib.licenses.gpl2;
      };
    };
    ini = "";
  };
# official postgres connector
 psql = rec {
   deriv = stdenv.mkDerivation rec {
    name = "psqlodbc-09.03.0100";
    buildInputs = [ unixODBC libtool postgresql openssl ];
    preConfigure="
      export CPPFLAGS=-I${unixODBC}/include
      export LDFLAGS='-L${unixODBC}/lib -lltdl'
    ";
    # added -ltdl to resolve missing references `dlsym' `dlerror' `dlopen' `dlclose' 
    src = fetchurl {
      url = "http://ftp.postgresql.org/pub/odbc/versions/src/${name}.tar.gz";
      sha256 = "0mh10chkmlppidnmvgbp47v5jnphsrls28zwbvyk2crcn8gdx9q1";
    };
    meta = {
        description = "unix odbc driver for postgresql";
        homepage =  http://pgfoundry.org/projects/psqlodbc/;
        license = "LGPL";
    };
  };
  ini = 
    "[PostgreSQL]\n" +
    "Description     = official PostgreSQL driver for Linux & Win32\n" +
    "Driver          = ${deriv}/lib/psqlodbcw.so\n" +
    "Threading       = 2\n";
 };
# mysql connector
# FIXME:
# $ LD_DEBUG=files isql -v mysql-test
#     [...]
#           7813:     /nix/store/vhapcwmifih3fnx0pc6d85fcficjbvnd-mysql-connector-odbc-5.2.6/lib/libmyodbc5w.so: error: symbol lookup error: undefined symbol: my_thread_end_wait_time (fatal)
#     [...]
#     [01000][unixODBC][Driver Manager]Can't open lib '/nix/store/vhapcwmifih3fnx0pc6d85fcficjbvnd-mysql-connector-odbc-5.2.6/lib/libmyodbc5w.so' : file not found
#     [ISQL]ERROR: Could not SQLConnect
 mysql = rec {
    deriv = stdenv.mkDerivation rec {
      name = "mysql-connector-odbc-5.2.6";
      src = fetchurl {
        url = "http://cdn.mysql.com/Downloads/Connector-ODBC/5.2/${name}-src.tar.gz";
        sha256 = "0yyi1bkyf0i6dixd8g8hz96j7k4l9bmyh8wdnifvn6c86lkblnq0";
      };
      buildInputs = [ cmake mysql zlib unixODBC ];
      # - The shipped CMakeLists.txt file doesn't find our lib. Tell it where it is.
      # - defining NONTHREADSAFE fixes
      #   libmyodbc5w.so: error: symbol lookup error: undefined symbol: my_thread_end_wait_time (fatal)
      # - MYSQL_LINK_FLAGS are broken (from bad parsing of mysql_config output?),
      #   seems like the end of the "mysql_config --cflags" output. Fix it by
      #   manually copying the output of "mysql_config --libs" (plus -pthread).
      preConfigure = ''
        export cmakeFlags="$cmakeFlags -DMYSQL_LIB=${mysql}/lib/mysql/libmysqlclient.so"
        export cmakeFlags="$cmakeFlags -DWITH_UNIXODBC=1"
        export cmakeFlags="$cmakeFlags -DMYSQLCLIENT_LIB_NAME=libmysqlclient.so"
        export cmakeFlags="$cmakeFlags -DNONTHREADSAFE=1"
        export cmakeFlagsArray+="-DMYSQL_LINK_FLAGS=$(mysql_config --libs) -pthread"
      '';
      postInstall = ''
        mkdir -p "$out/share/mysql-connector-odbc"
        for file in ChangeLog COPYING INSTALL Licenses_for_Third-Party_Components.txt README README.debug; do
            mv "$out/$file" "$out/share/mysql-connector-odbc"
        done
        rm -rf "$out/test"
      '';
      inherit mysql unixODBC;
    };
    ini =
      "[MYSQL]\n" +
      "Description     = MySQL driver\n" +
      "Driver          = ${deriv}/lib/libmyodbc5w.so\n" + # the 'a' is for ANSI, 'w' is for Unicode
      "CPTimeout       = \n" +
      "CPReuse         = \n" +
      "FileUsage       = 3\n ";
 };
 sqlite = rec {
    deriv = let version = "0.995"; in
    stdenv.mkDerivation {
      name = "sqlite-connector-odbc-${version}";

      src = fetchurl {
        url = "http://www.ch-werner.de/sqliteodbc/sqliteodbc-${version}.tar.gz";
        sha256 = "1r97fw6xy5w2f8c0ii7blfqfi6salvd3k8wnxpx9wqc1gxk8jnyy";
      };

      buildInputs = [ sqlite ];

      configureFlags = "--with-sqlite3=${sqlite} --with-odbc=${unixODBC}";

      # move libraries to $out/lib where they're expected to be
      postInstall = ''
        mkdir -p "$out/lib"
        mv "$out"/*.so "$out/lib"
        mv "$out"/*.la "$out/lib"
      '';

      meta = { 
        description = "ODBC driver for SQLite";
        homepage = http://www.ch-werner.de/sqliteodbc;
        license = stdenv.lib.licenses.bsd2;
        platforms = stdenv.lib.platforms.linux;
        maintainers = with stdenv.lib.maintainers; [ vlstill ];
      };
    };
    ini =
      "[SQLite]\n" +
      "Description     = SQLite ODBC Driver\n" +
      "Driver          = ${deriv}/lib/libsqlite3odbc.so\n" +
      "Setup           = ${deriv}/lib/libsqlite3odbc.so\n" +
      "Threading       = 2\n";
 };
}
