// Classe responsável por receber as requisições do componente Aura, processar os dados utilizando a classe SearchCompanyService e retornar as informações para o componente.
public class SearchCompanyAction {

    // Classes internas para estruturação dos dados de entrada e saída do método invocável. 
    // A classe Request recebe o CNPJ como parâmetro, 
    // enquanto a classe Response é utilizada para retornar os dados da empresa ou uma mensagem de erro, caso ocorra alguma exceção durante o processo.
    public class Request {
        @AuraEnabled @InvocableVariable(required=true)
        public String cnpj;
    }

    public class Response {
        @AuraEnabled @InvocableVariable public String cnpj;
        @AuraEnabled @InvocableVariable public String nome;
        @AuraEnabled @InvocableVariable public String billingStreet;
        @AuraEnabled @InvocableVariable public String numero;
        @AuraEnabled @InvocableVariable public String complemento;
        @AuraEnabled @InvocableVariable public String bairro;
        @AuraEnabled @InvocableVariable public String municipio;
        @AuraEnabled @InvocableVariable public String estado;
        @AuraEnabled @InvocableVariable public String cep;
        @AuraEnabled @InvocableVariable public String telefone;
        @AuraEnabled @InvocableVariable public String situacao;
        @AuraEnabled @InvocableVariable public String errorMessage;
        @AuraEnabled @InvocableVariable public Boolean accountAlreadyExists;
    }

    // Método invocável que será chamado pelo componente Aura. 
    // Ele usa listas por ser uma exigência dos métodos invocáveis, mesmo que, neste caso, seja processada apenas uma requisição por vez.
    @InvocableMethod(label='Buscar Empresa por CNPJ' description='Consulta dados na ReceitaWS a partir de um CNPJ')
    public static List<Response> getCompanyInfoByCnpj(List<Request> requests) {
        
        List<Response> results = new List<Response>();
        
        if (requests == null) return results;

        if(accountAlreadyExists(requests[0].cnpj)){
            Response r = new Response();
            r.accountAlreadyExists = true;
            r.cnpj = SearchCompanyService.stripNonDigits(requests[0].cnpj);
            results.add(r);
            return results;
        }
        
        // Itera sobre as requisições recebidas, chama o serviço de busca de empresa para cada CNPJ e popula a resposta.
        for (Request req : requests) {
            Response r = new Response();
            try {
                SearchCompanyDTO dto = SearchCompanyService.getCompanyByCnpj(req.cnpj);
                r.cnpj = dto.cnpj;
                r.nome = dto.nome;
                r.billingStreet = dto.billingStreet; 
                r.numero = dto.numero;
                r.complemento = dto.complemento;
                r.bairro = dto.bairro;
                r.municipio = dto.municipio;
                r.estado = dto.estado;
                r.cep = dto.cep;
                r.telefone = dto.telefone;
                r.situacao = dto.situacao;

            } catch (Exception e) {
                r.errorMessage = e.getMessage();
            }
            results.add(r);
        }
        return results;
    }

    private static Boolean accountAlreadyExists(String cnpj) {
        String cnpjFormatted = SearchCompanyService.stripNonDigits(cnpj);
        if(String.isBlank(cnpjFormatted) || cnpjFormatted.length() != 14){
            return false;
        }
        List<Account> accounts = [SELECT Id FROM Account WHERE CNPJ__c = :cnpjFormatted LIMIT 1];
        return !accounts.isEmpty();
    }

}
