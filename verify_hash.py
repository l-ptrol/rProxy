import struct
import hashlib

def md4(data):
    def f(x, y, z): return (x & y) | (~x & z)
    def g(x, y, z): return (x & y) | (x & z) | (y & z)
    def h(x, y, z): return x ^ y ^ z
    def rot(x, n): return ((x << n) | (x >> (32 - n))) & 0xffffffff
    
    msg = data + b'\x80'
    while len(msg) % 64 != 56: msg += b'\x00'
    msg += struct.pack('<Q', len(data) * 8)
    
    a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    for i in range(0, len(msg), 64):
        x = struct.unpack('<16I', msg[i:i+64])
        aa, bb, cc, dd = a, b, c, d
        for j in range(16):
            a = rot((a + f(b, c, d) + x[j]) & 0xffffffff, [3, 7, 11, 19][j % 4])
            a, b, c, d = d, a, b, c
        for j in range(16):
            a = rot((a + g(b, c, d) + x[[0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15][j]] + 0x5a827999) & 0xffffffff, [3, 5, 9, 13][j % 4])
            a, b, c, d = d, a, b, c
        for j in range(16):
            a = rot((a + h(b, c, d) + x[[0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15][j]] + 0x6ed9eba1) & 0xffffffff, [3, 9, 11, 15][j % 4])
            a, b, c, d = d, a, b, c
        a, b, c, d = (a + aa) & 0xffffffff, (b + bb) & 0xffffffff, (c + cc) & 0xffffffff, (d + dd) & 0xffffffff
    
    return struct.pack('<4I', a, b, c, d).hex()

def verify():
    # Данные из дампа пользователя
    USER = "admin"
    PASS = "12985654"
    realm = "Keenetic Xiaomi R3P"
    challenge = "LRIGGJJDBXQEZHCPQXOWCRLGFKWMYGXL"
    h1 = "7984d1dba41fe075f1d7d1848432aaa0"
    browser_hash = "f3aa27cf6a3c1d562eab5a167987289226c519deab7395d0b382cf7436443253"
    
    nt_hash_browser = "b32107cd9056326b61081f4fb2eec1b3"
    nt_hash_calc = md4(PASS.encode('utf-16le'))
    print(f"NT Hash Calc: {nt_hash_calc} {'!!! MATCH !!!' if nt_hash_calc == nt_hash_browser else ''}")
    
    session_id = "DFXNAXYBKRVQLFXE"
    session_cookie = "WFGGPJJTF"
    
    h1_md5 = h1
    h1_sha256 = hashlib.sha256(f"{USER}:{realm}:{PASS}".encode()).hexdigest()
    h1_md5_utf16 = hashlib.md5(f"{USER}:{realm}:{PASS}".encode('utf-16le')).hexdigest()
    h1_sha256_utf16 = hashlib.sha256(f"{USER}:{realm}:{PASS}".encode('utf-16le')).hexdigest()
    
    hashes = {
        "PASS": PASS,
        "MD5(PASS)": hashlib.md5(PASS.encode()).hexdigest(),
        "MD5(USER:REALM:PASS)": h1,
        "SHA256(PASS)": hashlib.sha256(PASS.encode()).hexdigest(),
        "SHA256(USER:REALM:PASS)": hashlib.sha256(f"{USER}:{realm}:{PASS}".encode()).hexdigest(),
        "MD5_UTF16(PASS)": hashlib.md5(PASS.encode('utf-16le')).hexdigest(),
        "MD5_UTF16(USER:REALM:PASS)": hashlib.md5(f"{USER}:{realm}:{PASS}".encode('utf-16le')).hexdigest(),
    }
    
    salts = {
        "challenge": challenge,
        "session_id": session_id,
        "cookie": session_cookie,
    }
    
    salts = {
        "challenge": challenge,
        "session_id": session_id,
        "cookie_name": session_cookie,
        "cookie_val": "KCLGIRELMRJBDBNA",
        "phpsessid": "8494617368be96016d63e03b211d550a",
    }
    
    h1_sha256_full = hashlib.sha256(f"{USER}:{realm}:{PASS}".encode()).hexdigest()
    h1_sha256_no_realm = hashlib.sha256(f"{USER}:{PASS}".encode()).hexdigest()
    
    final_variants = {
        "SHA256(challenge + SHA256_full)": hashlib.sha256((challenge + h1_sha256_full).encode()).hexdigest(),
        "SHA256(challenge + SHA256_no_realm)": hashlib.sha256((challenge + h1_sha256_no_realm).encode()).hexdigest(),
        "SHA256(challenge + MD5_h1)": hashlib.sha256((challenge + h1).encode()).hexdigest(),
    }
    
    # И вариант с двоеточием
    final_variants["SHA256(challenge + ':' + MD5_h1)"] = hashlib.sha256((challenge + ":" + h1).encode()).hexdigest()

    print(f"Target Browser Hash: {browser_hash}")
    for name, val in final_variants.items():
        if val == browser_hash:
            print(f"!!! MATCH !!! {name}: {val}")
        else:
            print(f"Checked {name}: {val}")

if __name__ == "__main__":
    verify()

if __name__ == "__main__":
    verify()
