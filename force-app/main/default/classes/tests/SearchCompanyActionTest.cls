@IsTest
private class SearchCompanyActionTest {

    @IsTest
    static void testSuccess() {
        Test.setMock(HttpCalloutMock.class, new ReceitaWsCalloutMock());

        SearchCompanyAction.Request req = new SearchCompanyAction.Request();
        req.cnpj = '12.345.678/0001-95';

        List<SearchCompanyAction.Response> results = 
            SearchCompanyAction.getCompanyInfoByCnpj(new List<SearchCompanyAction.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals('12345678000195', results[0].cnpj);
        System.assertEquals('Empresa Teste Ltda', results[0].nome);
        System.assertEquals('Rua Teste - 123 - Sala 1 - Centro', results[0].billingStreet);
        System.assertEquals(null, results[0].errorMessage);
    }

    @IsTest
    static void testInvalidCnpj() {
        SearchCompanyAction.Request req = new SearchCompanyAction.Request();
        req.cnpj = 'invalid_cnpj';

        List<SearchCompanyAction.Response> results = 
            SearchCompanyAction.getCompanyInfoByCnpj(new List<SearchCompanyAction.Request>{ req });

        System.assertEquals(1, results.size());
        System.assertEquals('CNPJ inválido ou em branco!', results[0].errorMessage);
    }

    @IsTest
    static void testNullRequests() {
        List<SearchCompanyAction.Response> results = 
            SearchCompanyAction.getCompanyInfoByCnpj(null);

        System.assertEquals(0, results.size());
    }
}