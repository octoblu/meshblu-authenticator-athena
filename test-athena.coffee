envalid       = require 'envalid'
AthenaService = require './src/services/athena-service'

envConfig = {
  ATHENA_URL: envalid.url({ default: 'https://accounts.cloud.com' })
  REDIRECT_URL: envalid.url()
  CLIENT_ID: envalid.str()
  CLIENT_SECRET: envalid.str()
}

# https://athena.dev.octo.space/authenticate?callbackUrl=https%3A%2F%2Fcontroller.dev.octo.space%2F&domain=dev.octo.space&authDomainName=demo-octo-space

class TestAthena
  constructor: ->
    @env = envalid.cleanEnv process.env, envConfig

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    athenaService = new AthenaService @env
    options =
      tenantId: '809dc3fe-0a7e-4e76-b400-53f6a29ca6c7'
      domain: 'demo.octo.space'
      name: 'Demo Smart Spaces'
    athenaService.getCustomerByDomain { domain: 'demo-octo-space' }, (error, customer) =>
      return @panic error if error?
      console.log 'customer', JSON.stringify customer, null, 2
      athenaService.createAzureCustomer options, (error) =>
        return @panic error if error?
        athenaService.getCustomerPrincipals { customerId: customer.cust_id }, (error, principals) =>
          return @panic error if error?
          console.log 'principals', JSON.stringify principals, null, 2
          athenaService.attachPrincipalToCustomer { sub: '3166342166364110850', customerId: customer.cust_id }, (error, result) =>
            return @panic error if error?
            console.log 'result', JSON.stringify result, null, 2
            process.exit 0

testAthena = new TestAthena()
testAthena.run()
