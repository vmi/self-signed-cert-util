#!/usr/bin/awk -f

function modify_entry(sec) {
    switch (sec) {
    case "CA_default":
        switch ($1) {
        case "dir":
            $3 = "."
            break
        case "new_certs_dir":
            $3 = "."
            break
        case "certificate":
            $3 = "$dir/ca.crt"
            break
        case "private_key":
            $3 = "$dir/ca.key"
            break
        case "default_days":
        case "default_crl_days":
            $3 = "36525"
            break
        case "x509_extensions":
            next
        }
        break
    case "req":
        switch ($1) {
        case "x509_extensions":
            next
        }
        break
    case "usr_cert":
        switch ($1) {
        case "authorityKeyIdentifier":
            $3 = "keyid,issuer:always"
            break
        }
        break
    default:
        break
    }
}

function append_entry(sec) {
    switch (sec) {
    case "req":
        print "req_extensions = v3_req"
        break
    case "usr_cert":
        print "subjectAltName = " alt_name
        break
    case "v3_req":
        print "subjectAltName = " alt_name
        break
    default:
        break
    }
}

function append_section() {
    print ""
    print "[ private_ca ]"
    print "nameConstraints = critical,permitted;" constraints
}

BEGIN {
    section = ""
}

/^\s*(#.*)?$/ {
    next
}

$1 == "[" {
    append_entry(section)
    section = $2
    print ""
}

{
    sub(/\s*(#.*)$/, "")
    sub(/\s*=\s*/, " = ")
    modify_entry(section)
    print
}

END {
    append_entry(section)
    append_section()
}
