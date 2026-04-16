public with sharing class AddressFormatter {

    // Método auxiliar para construir o endereço completo a partir dos campos retornados pela API. 
    // Ele verifica se cada parte do endereço é preenchida antes de adicioná-la à string final, 
    // garantindo que não haja espaços ou caracteres desnecessários caso algum campo esteja vazio.
    public static String buildBillingStreetAddress(String logradouro, String numero, String complemento, String bairro) {
        List<String> parts = new List<String>();

        if(String.isNotBlank(logradouro)) parts.add(logradouro);
        if(String.isNotBlank(numero)) parts.add(numero);
        if(String.isNotBlank(complemento)) parts.add(complemento);
        if(String.isNotBlank(bairro)) parts.add(bairro);

        return String.join(parts, ' - ');
    }
}