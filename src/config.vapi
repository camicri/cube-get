[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
        public const string GETTEXT_PACKAGE;
        public const string SPRITE_DIR;
        public const string BACKGROUND_DIR;
        public const string PACKAGE_DATA_DIR;
        public const string PACKAGE_LOCALE_DIR;
        public const string PACKAGE_NAME;
        public const string PACKAGE_VERSION;
        public const string VERSION;

        [CCode (cheader_filename = "arpa/inet.h")]
	    public uint32 htonl (uint32 hostlong);
	    [CCode (cheader_filename = "arpa/inet.h")]
	    public uint32 ntohl (uint32 netlong);
	    [CCode (cheader_filename = "arpa/inet.h")]
	    public uint16 htons (uint16 hostshort);
	    [CCode (cheader_filename = "arpa/inet.h")]
	    public uint16 ntohs (uint16 netshort);
}