import { api, LightningElement } from 'lwc';

export default class Imcc_richTextEditor extends LightningElement {
    @api rlabel;
    @api rvalue;
    @api qnaireId;
    allowedFormats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'image',
        'clean',
        'table',
        'header',
        'color'        
    ];

    handleChange(event){
        let info = event.detail.value;        
        this.dispatchEvent(new CustomEvent('setinfo',{ detail: {data:info} }));
    }
}