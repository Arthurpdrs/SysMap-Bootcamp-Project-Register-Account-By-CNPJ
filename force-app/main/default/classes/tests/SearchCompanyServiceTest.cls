@IsTest
private with sharing class SearchCompanyServiceTest {
    
    @IsTest
    static void testGetCompanyByCnpjSuccess() {
        // Arrange
        String cnpj = '12.345.678/0001-95';
        Test.setMock(HttpCalloutMock.class, new ReceitaWsCalloutMock());
        
        // Act
        SearchCompanyDTO result = SearchCompanyService.getCompanyByCnpj(cnpj);
        
        // Assert
        System.assertNotEquals(null, result);
        System.assertEquals('12345678000195', result.cnpj);
        System.assertEquals('Empresa Teste Ltda', result.nome);
        System.assertEquals('Rua Teste - 123 - Sala 1 - Centro', result.billingStreet);
    }

    @IsTest
    static void testGetCompanyByCnpjInvalidCnpj(){
        String cnpj = 'invalid_cnpj';
        try {
            SearchCompanyService.getCompanyByCnpj(cnpj);
            System.assert(false, 'Expected an exception for invalid CNPJ');
        } catch (AuraHandledException e) {
            System.assertEquals('CNPJ inválido ou em branco!', e.getMessage());
        }
}

    @IsTest
    static void testGetCompanyByCnpjNotFound(){
        String cnpj = '00.000.000/0000-00';
        Test.setMock(HttpCalloutMock.class, new ReceitaWsCalloutMock(400, ReceitaWsCalloutMock.getErrorBody()));
        try {
            SearchCompanyService.getCompanyByCnpj(cnpj);
            System.assert(false, 'Expected an exception for CNPJ not found');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Erro ao consultar CNPJ em ReceitaWS'));
        }
    }

    @IsTest
    static void testGetCompanyByCnpjCalloutError(){
        String cnpj = '12.345.678/0001-95';
        Test.setMock(HttpCalloutMock.class, new ReceitaWsCalloutMock(200, '{"status":"ERROR","message":"Internal Server Error"}'));
        try {
            SearchCompanyService.getCompanyByCnpj(cnpj);
            System.assert(false, 'Expected an exception for callout error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Erro ao consultar CNPJ em ReceitaWS'));
        }
    }
    
}