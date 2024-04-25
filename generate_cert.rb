require 'openssl'
require 'fileutils'
require 'tzinfo'

def save_cert_to_file(cert, key, cert_path, key_path)
  File.write(cert_path, cert.to_pem)
  File.write(key_path, key.to_pem)
end

def local_to_utc(local_time, timezone)
  timezone.local_to_utc(local_time)
end

timezone = TZInfo::Timezone.get('America/Sao_Paulo')

not_after = local_to_utc(Time.now + 10 * 365 * 24 * 60 * 60, timezone)
not_before = local_to_utc(Time.now - 2 * 24 * 60 * 60, timezone)

# Criação do CA root:
base_cn = 'example.test'
subject = "/CN=#{base_cn}"

key = OpenSSL::PKey::RSA.new(4096)

cert = OpenSSL::X509::Certificate.new
cert.version = 2
cert.serial = 0x0
cert.subject = OpenSSL::X509::Name.parse(subject)
cert.issuer = cert.subject
cert.public_key = key.public_key

cert.not_before = not_before
cert.not_after = not_after

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = cert
ef.issuer_certificate = cert
cert.extensions = [
  ef.create_extension('basicConstraints', 'CA:TRUE', true),
  ef.create_extension('keyUsage', 'keyCertSign, cRLSign', true),
  ef.create_extension('subjectKeyIdentifier', 'hash', false),
  ef.create_extension('authorityKeyIdentifier', 'keyid', false) # keyid:always nao acha
]

signed_cert = cert.sign(key, OpenSSL::Digest.new('SHA256'))

# Salvar certificado com o category Root
ca_root_cert_path = 'nginx/certs/ca_root.crt'
ca_root_key_path = 'nginx/certs/ca_root.key'
save_cert_to_file(cert, key, ca_root_cert_path, ca_root_key_path)

# Criação de um certificado server, a partir de um certificado root:

root_cert = OpenSSL::X509::Certificate.new(File.read('nginx/certs/ca_root.crt'))
root_key = OpenSSL::PKey::RSA.new(File.read('nginx/certs/ca_root.key'))

base_cn = 'example.test'
subject = "/CN=#{base_cn}/"

server_key = OpenSSL::PKey::RSA.new(4096)

server_cert = OpenSSL::X509::Certificate.new
server_cert.version = 2 # Versão 3 do X.509
server_cert.serial = 1 # Definir o número de série do certificado
server_cert.subject = OpenSSL::X509::Name.parse(subject)
server_cert.issuer = root_cert.subject # Certificado root será o emissor
server_cert.public_key = server_key.public_key # Chave pública do servidor

server_cert.not_before = Time.now
server_cert.not_after = Time.now + (5 * 365 * 24 * 60 * 60)

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = server_cert
ef.issuer_certificate = root_cert
server_cert.extensions = [
  ef.create_extension('keyUsage', 'digitalSignature', true),
  ef.create_extension('subjectKeyIdentifier', 'hash', false)
]

server_cert.sign(root_key, OpenSSL::Digest.new('SHA256'))

server_cert_path = 'nginx/certs/server.crt'
server_key_path = 'nginx/certs/server.key'
save_cert_to_file(server_cert, server_key, server_cert_path, server_key_path)

# Criação de um certificado client, a partir de um certificado root:

base_cn = 'client.com.br'
subject = "/CN=#{base_cn}/"

# Gerar uma chave privada RSA de 4096 bits para o cliente
client_key = OpenSSL::PKey::RSA.new(4096)

# Criar o certificado do cliente
client_cert = OpenSSL::X509::Certificate.new
client_cert.version = 2 # Certificado X.509 v3
client_cert.serial = 2 # Número serial do certificado (garantir que é único)

# Configurar as datas de validade
client_cert.not_before = Time.now
client_cert.not_after = Time.now + (365 * 24 * 60 * 60) # 1 ano de validade

# Definir o sujeito do certificado do cliente
client_cert.subject = OpenSSL::X509::Name.parse(subject)

client_cert.issuer = root_cert.subject # Certificado raiz é o emissor
client_cert.public_key = client_key.public_key # Chave pública do cliente

# Assinatura do certificado do cliente com a chave raiz
client_cert.sign(root_key, OpenSSL::Digest.new('SHA256'))

client_cert_path = 'nginx/certs/client.crt'
client_key_path = 'nginx/certs/client.key'
save_cert_to_file(client_cert, client_key, client_cert_path, client_key_path)
