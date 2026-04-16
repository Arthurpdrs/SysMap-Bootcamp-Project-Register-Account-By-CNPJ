@IsTest
global class ReceitaWsCalloutMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    // Construtor padrão (sucesso)
    public ReceitaWsCalloutMock() {
        this.statusCode = 200;
        this.responseBody = getSuccessBody();
    }

    // Construtor customizável
    public ReceitaWsCalloutMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setBody(responseBody);
        return res;
    }

    // Helpers para reutilizar nos testes
    public static String getSuccessBody() {
        return '{"cnpj":"12345678000195","nome":"Empresa Teste Ltda","logradouro":"Rua Teste","numero":"123","complemento":"Sala 1","bairro":"Centro","municipio":"São Paulo","uf":"SP","cep":"01001000","telefone":"11999999999","situacao":"Ativa"}';
    }

    public static String getErrorBody() {
        return '{"status":"ERROR","message":"CNPJ inválido"}';
    }
}