public class SearchCompanyService {

    @AuraEnabled
    public static SearchCompanyDTO getCompanyByCnpj(String cnpj){
        String cnpjFormatted = validateCnpj(cnpj);
        HttpResponse response = doCallout(cnpjFormatted);
        Map<String,Object> data = parseResponse(response);
        return new SearchCompanyDTO(data);
    }
    
    // Valida o CNPJ, garantindo que ele tenha 14 dígitos numéricos. Evita callouts desnecessários para CNPJs claramente inválidos.  
    @TestVisible
    private static String validateCnpj(String cnpj){
        
        String cnpjFormatted = stripNonDigits(cnpj);

        if(cnpjFormatted == null || cnpjFormatted.length() != 14){
            String errorMessage = 'CNPJ inválido ou em branco!';
            AuraHandledException ahe = new AuraHandledException(errorMessage);
            ahe.setMessage(errorMessage);
            throw ahe;
        }
        return cnpjFormatted;
    }

    // Callout para a API externa (ReceitaWs). 
    @TestVisible
    private static HttpResponse doCallout(String cnpjFormatted){

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpoint(cnpjFormatted));
        request.setMethod('GET');
        request.setTimeout(60000);
        request.setHeader('Accept', 'application/json');
        return http.send(request);
    }
                   
    // Desserializa a resposta JSON em um Map. Em caso de status code 200, mas com status 'ERROR' na resposta, lança uma exceção com a mensagem retornada pela API. 
    @TestVisible
    private static Map<String,Object> parseResponse(HttpResponse response){
        if(response.getStatusCode() != 200){
            String errorMessage = 'Erro ao consultar CNPJ em ReceitaWS: ' + response.getStatusCode();
            AuraHandledException ahe = new AuraHandledException(errorMessage);
            ahe.setMessage(errorMessage);
            throw ahe;
        }

        Map<String,Object> data = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        
        String status = (String)data.get('status');
        if(status != null && status == 'ERROR'){
            String errorMessage = 'CNPJ não encontrado: ' + (String)data.get('message');
            AuraHandledException ahe = new AuraHandledException(errorMessage);
            ahe.setMessage(errorMessage);
            throw ahe;
        }

        return data;
    }

    // Método separado para facilitar testes e futura migração para Named Credentials
    @TestVisible
    private static String getEndpoint(String cnpjFormatted){
        return 'https://receitaws.com.br/v1/cnpj/' + cnpjFormatted;
    }

    // Método para normalizar o cnpj, removendo caracteres não numéricos. 
    @TestVisible
    private static String stripNonDigits(String cnpj) {
        if (cnpj == null || cnpj == '') return null;
        return cnpj.replaceAll('[^0-9]', '');
    }

}