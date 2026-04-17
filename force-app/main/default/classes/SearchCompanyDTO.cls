public class SearchCompanyDTO {

    public String cnpj;
    public String nome;
    public String billingStreet;
    public String logradouro;
    public String numero;
    public String complemento;
    public String bairro;
    public String municipio;
    public String estado;
    public String cep;
    public String telefone;
    public String situacao;
    
    public SearchCompanyDTO(Map<String, Object> data) {
        // Normaliza o CNPJ, removendo caracteres não numéricos, para garantir consistência no formato do CNPJ em toda a aplicação.
        this.cnpj = SearchCompanyService.stripNonDigits((String)data.get('cnpj'));
        this.nome = (String)data.get('nome');
        this.logradouro = (String)data.get('logradouro');
        this.numero = (String)data.get('numero');
        this.complemento = (String)data.get('complemento');
        this.bairro = (String)data.get('bairro');
        this.municipio = (String)data.get('municipio');
        this.estado = (String)data.get('uf');
        this.cep = (String)data.get('cep');
        this.telefone = (String)data.get('telefone');
        this.situacao = (String)data.get('situacao');
        // Monta o endereço completo para o campo billingStreet, utilizando um método auxiliar da classe AddressFormatter.
        // Dessa forma, é possível exibir o endereço completo em um único campo no componente Aura.
        this.billingStreet = AddressFormatter.buildBillingStreetAddress(this.logradouro, this.numero, this.complemento, this.bairro);
    }

}