L.Control.Slider = L.Control.extend({
    update: function(value){
        return value;
    },

    options: {
        size: '100px',
        position: 'topright',
        min: 0,
        max: 250,
        step: 1,
        id: "slider",
        value: 50,
        collapsed: true,
        title: 'Leaflet Slider',
        logo: 'S',
        orientation: 'horizontal',
        increment: false,
        getValue: function(value) {
            return value;
        },
        showValue: true,
        syncSlider: false
    },
    initialize: function (f, options) {
        L.setOptions(this, options);
        if (typeof f == "function") {
            this.update = f;
        } else {
            this.update = function (value) {
                console.log(value);
            };
        }
        if (typeof this.options.getValue != "function") {
            this.options.getValue = function (value) {
                return value;
            };
        }
        if (this.options.orientation!='vertical') {
            this.options.orientation = 'horizontal';
        }
    },
    onAdd: function (map) {
        this._initLayout();
        this.update(this.options.value+"");
        return this._container;
    },
    _updateValue: function () {
        this.value = this.slider.value;
        if (this.options.showValue){
    	   this._sliderValue.innerHTML = this.options.getValue(this.value);
            this._sliderValue.value = this.options.getValue(this.value);
        }
        this._sliderLink.innerHTML = this.options.getValue(this.value);
        this.update(this.value);
    },
    _updateValueInput: function (event) {
        var useTimes;
        if(times.indexOf != undefined){
            useTimes = times;
        }else{
            useTimes = times[varName];
        }

        if(useTimes.indexOf(this._sliderValue.value)!=-1 && this.slider.value!=useTimes.indexOf(this._sliderValue.value)){
            this.slider.value = useTimes.indexOf(this._sliderValue.value);
            this._updateValue();
        }
    },
    _initLayout: function () {
        var className = 'leaflet-control-slider';
        this._container = L.DomUtil.create('div', className + ' ' +className + '-' + this.options.orientation);
        this._sliderLink = L.DomUtil.create('a', className + '-toggle', this._container);
        this._sliderLink.setAttribute("title", this.options.title);
        // this._sliderLink.innerHTML = this.options.logo;
        this._sliderLink.innerHTML = this.options.getValue(this.options.value);

        if (this.options.showValue){
            // this._sliderValue = L.DomUtil.create('p', className+'-value', this._container);
            this._sliderValue = L.DomUtil.create('input', className+'-value', this._container);
            L.DomEvent.on(this._sliderValue, 'keyup', this._updateValueInput, this);
            this._sliderValue.innerHTML = this.options.getValue(this.options.value);
            this._sliderValue.value = this.options.getValue(this.options.value);
        }

        this._containerDiv = L.DomUtil.create('div', 'container-div', this._container);

        if(this.options.increment) {
            this._plus = L.DomUtil.create('a', className + '-plus', this._containerDiv);
            this._plus.innerHTML = "+";
            L.DomEvent.on(this._plus, 'click', this._increment, this);
            L.DomUtil.addClass(this._container, 'leaflet-control-slider-incdec');
        }

        this._sliderContainer = L.DomUtil.create('div', 'leaflet-slider-container', this._containerDiv);
        this.slider = L.DomUtil.create('input', 'leaflet-slider', this._sliderContainer);
        if (this.options.orientation == 'vertical') {this.slider.setAttribute("orient", "vertical");}
        this.slider.setAttribute("title", this.options.title);
        this.slider.setAttribute("id", this.options.id);
        this.slider.setAttribute("type", "range");
        this.slider.setAttribute("min", this.options.min);
        this.slider.setAttribute("max", this.options.max);
        this.slider.setAttribute("step", this.options.step);
        this.slider.setAttribute("value", this.options.value);
        if (this.options.syncSlider) {
            L.DomEvent.on(this.slider, "input", function (e) {
                this._updateValue();
            }, this);
        } else {
            L.DomEvent.on(this.slider, "change", function (e) {
                this._updateValue();
            }, this);
        }

        if(this.options.increment) {
            this._minus = L.DomUtil.create('a', className + '-minus', this._containerDiv);
            this._minus.innerHTML = "-";
            L.DomEvent.on(this._minus, 'click', this._decrement, this);
        }

        if (this.options.showValue){
            if (window.matchMedia("screen and (-webkit-min-device-pixel-ratio:0)").matches && this.options.orientation =='vertical') {this.slider.style.width = (this.options.size.replace('px','') -36) +'px'; this._sliderContainer.style.height = (this.options.size.replace('px','') -36) +'px';}
            else if (this.options.orientation =='vertical') {this._sliderContainer.style.height = (this.options.size.replace('px','') -36) +'px';}
            else {this._sliderContainer.style.width = (this.options.size.replace('px','') -56) +'px';}
        } else {
            if (window.matchMedia("screen and (-webkit-min-device-pixel-ratio:0)").matches && this.options.orientation =='vertical') {this.slider.style.width = (this.options.size.replace('px','') -10) +'px'; this._sliderContainer.style.height = (this.options.size.replace('px','') -10) +'px';}
            else if (this.options.orientation =='vertical') {this._sliderContainer.style.height = (this.options.size.replace('px','') -10) +'px';}
            else {this._sliderContainer.style.width = (this.options.size.replace('px','') -25) +'px';}
        }

        L.DomEvent.disableClickPropagation(this._container);

        if (this.options.collapsed) {
            if (!L.Browser.android) {
                L.DomEvent
                    .on(this._container, 'mouseenter', this._expand, this)
                    .on(this._container, 'mouseleave', this._collapse, this);
            }

            if (L.Browser.touch) {
                L.DomEvent
                    .on(this._sliderLink, 'click', L.DomEvent.stop)
                    .on(this._sliderLink, 'click', this._expand, this);
            } else {
                L.DomEvent.on(this._sliderLink, 'focus', this._expand, this);
            }
        } else {
            this._expand();
        }
    },
    _expand: function () {
        L.DomUtil.addClass(this._container, 'leaflet-control-slider-expanded');
    },
    _collapse: function () {
        L.DomUtil.removeClass(this._container, 'leaflet-control-slider-expanded');
    },
    _increment: function () {
        //console.log(this.slider.value-this.slider.step + " " + this.slider.value+this.slider.step);
        this.slider.value = this.slider.value*1+this.slider.step*1;
        this._updateValue();
    },
    _decrement: function () {
        //console.log(this.slider.value-this.slider.step + " " + this.slider.value+this.slider.step);
        this.slider.value = this.slider.value*1-this.slider.step*1;
        this._updateValue();
    }


});
L.control.slider = function (f, options) {
    return new L.Control.Slider(f, options);
 };
