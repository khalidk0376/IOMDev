import { LightningElement } from 'lwc';
const DELAY = 3000; //ms
export default class ImccSlider extends LightningElement {
    _isLoaded;
    current;
    maxLeft;
    autoChange;
    connectedCallback(){
        this._isLoaded = false;
        this.current = 0;
    }
    renderedCallback(){
        const slides = this.template.querySelector('.slides');
        if(slides && !this._isLoaded){            
            this._isLoaded = true;
            const slidesCount = this.template.querySelectorAll('.slide').length;
            this.maxLeft = (slidesCount - 3) * 100 * -1;            
            this.current = 0;
            this.autoChange = setInterval(()=>{
                this.changeSlide();
            }, DELAY);
        }
    }

    changeSlide(next = true) {
        const slides = this.template.querySelector('.slides');
        if (next) {
          this.current += this.current > this.maxLeft ? -100 : this.current * -1;
        } else {
            this.current = this.current < 0 ? this.current + 100 : this.maxLeft;
        }      
        slides.style.left = (this.current/3) + "%";
    }

    next(){
        this.changeSlide();
        this.reset();
    }

    back(){
        this.changeSlide(false);
        this.reset();
    }

    reset(){
        clearInterval(this.autoChange);
        this.autoChange = setInterval(()=>{
            this.changeSlide(slides,true);
        }, DELAY);
    }
}