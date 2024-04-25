# servidor nginx mTLS
ref: https://github.com/MichaelViveros/nginx-mutual-tls

## Passos

instale as gems e rode no shell:

```sh
#!/bin/bash
bundle
mkdir nginx/certs
ruby generate_cert.rb
```

Isso deve gerar os certificados de client, server e root.

Subir o container:

```sh
#!/bin/bash
docker-compose up
```

Entre no Postman e faça uma chamada get em localhost:443 sem certificado
Depois configure o certificado client para fazer chamadas em localhost:443.
