module Vault
  # Monkey patch to support k8s authenticaiton. Taken from https://github.com/hashicorp/vault-ruby/pull/202
  class Authenticate < Request
    def kubernetes(role, route = nil, service_token_path = nil)
      route ||= '/v1/auth/kubernetes/login'
      service_token_path ||= '/var/run/secrets/kubernetes.io/serviceaccount/token'

      payload = {
        role: role,
        jwt: File.read(service_token_path)
      }

      json = client.post(route, JSON.fast_generate(payload))

      secret = Secret.decode(json)
      client.token = secret.auth.client_token

      secret
    end
  end
end
