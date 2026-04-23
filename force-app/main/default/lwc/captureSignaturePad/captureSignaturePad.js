import { LightningElement } from 'lwc';

export default class CaptureSignaturePad extends LightningElement {


    imgSrc;
    inputText = '';
    isDrawingSignature = false;
    drawingSections = [];
    canvas;
    context2d;

    enableNameSigning = true;
    enableSignatureDrawing = true;
    strokeThickness = 2;
    penColor = 'black';
    padColor = 'white';
    font = "30px 'Great Vibes'";
    nameInputLabel = 'Type name here:';
    padLabel = 'Or draw signature here:';

    renderedCallback() {
        if (!this.canvas) {
            this.canvas = this.template.querySelector("canvas");
            this.context2d = this.canvas.getContext("2d");
            this.context2d.font = this.font;
            this.refreshCanvas(true);
            this.addEventListeners();
        }
    }

    addEventListeners() {
        if (this.enableSignatureDrawing) {
            this.canvas.addEventListener("mousemove", this.onMouseMove.bind(this));
            this.canvas.addEventListener("mousedown", this.onMouseDown.bind(this));
            this.canvas.addEventListener("mouseup", this.onMouseUp.bind(this));
            this.canvas.addEventListener("mouseout", this.onMouseOut.bind(this));

            this.canvas.addEventListener("touchstart", this.onTouchStart.bind(this));
            this.canvas.addEventListener("touchmove", this.onTouchMove.bind(this));
            this.canvas.addEventListener("touchend", this.onTouchEnd.bind(this));
        }

        window.addEventListener("resize", this.refreshCanvas.bind(this));
    }

    // Mouse and touch event handlers
    onMouseDown(event) {
        event.preventDefault();
        this.recordPointer(event, true);
        this.isDrawingSignature = true;
    }

    onMouseMove(event) {
        if (this.isDrawingSignature) {
            this.recordPointer(event, false);
        }
    }

    onMouseUp() {
        this.isDrawingSignature = false;
    }

    onMouseOut() {
        this.isDrawingSignature = false;
    }

    onTouchStart(event) {
        if (event.targetTouches.length === 1) {
            this.recordPointer(event, true);
            this.isDrawingSignature = true;
        }
    }

    onTouchMove(event) {
        if (this.isDrawingSignature) {
            event.preventDefault();
            this.recordPointer(event, false);
        }
    }

    onTouchEnd() {
        this.isDrawingSignature = false;
    }

    // Handle input for name signing
    handleNameInput(event) {
        this.inputText = event.detail.value;
        this.refreshCanvas(true);
    }

    // Record drawing points and refresh canvas
    recordPointer(event, isNewSection) {
        const clientX = event.clientX || event.touches[0].clientX;
        const clientY = event.clientY || event.touches[0].clientY;
        const clientRect = this.canvas.getBoundingClientRect();
        const pointX = clientX - clientRect.left;
        const pointY = clientY - clientRect.top;

        if (isNewSection || this.drawingSections.length < 1) {
            this.drawingSections.push([{ x: pointX, y: pointY }]);
        } else {
            const lastSectionIdx = this.drawingSections.length - 1;
            const lastSection = this.drawingSections[lastSectionIdx];
            lastSection.push({ x: pointX, y: pointY });
        }

        this.refreshCanvas();
    }

    // Refresh the canvas based on the drawing sections
    refreshCanvas(forceFullRedraw = false) {
        let isFullRedraw = forceFullRedraw;

        if (this.canvas.width !== this.canvas.clientWidth || this.canvas.height !== this.canvas.clientHeight) {
            this.canvas.width = this.canvas.clientWidth;
            this.canvas.height = this.canvas.clientHeight;
            isFullRedraw = true;
        }

        if (isFullRedraw) {
            this.canvas.style.backgroundColor = this.padColor;
            this.context2d.clearRect(0, 0, this.canvas.width, this.canvas.height);
        }

        if (this.enableSignatureDrawing && this.drawingSections.length > 0) {
            this.context2d.lineCap = "round";
            this.context2d.lineJoin = "round";
            this.context2d.strokeStyle = this.penColor;
            this.context2d.lineWidth = this.strokeThickness;

            if (isFullRedraw) {
                this.drawingSections.forEach((section) => {
                    if (section.length > 1) {
                        this.context2d.beginPath();
                        this.context2d.moveTo(section[0].x, section[0].y);
                        for (let i = 1; i < section.length; i++) {
                            this.context2d.lineTo(section[i].x, section[i].y);
                        }
                        this.context2d.stroke();
                    }
                });
            } else {
                const lastSection = this.drawingSections[this.drawingSections.length - 1];
                const p1 = lastSection[lastSection.length - 2];
                const p2 = lastSection[lastSection.length - 1];
                if (p1 && p2) {
                    this.context2d.beginPath();
                    this.context2d.moveTo(p1.x, p1.y);
                    this.context2d.lineTo(p2.x, p2.y);
                    this.context2d.stroke();
                }
            }
        }

        if (this.inputText && isFullRedraw) {
            const textStartX = 8;
            const textStartY = this.canvas.height / 2;

            this.context2d.font = this.font;
            this.context2d.fillStyle = this.penColor;

            this.context2d.fillText(this.inputText, textStartX, textStartY);
        }
    }

    // Clear the signature and name input
    clearSignature() {
        this.inputText = "";
        this.drawingSections = [];
        //this.refreshCanvas(true);
        this.imgSrc = null;
    }

    // Save the signature
    saveSignature() {
        const dataURL = this.getSignature();
        if (dataURL) {
            this.imgSrc = dataURL;
        }
    }

    getSignature() {
        let cv = document.createElement("canvas");
        let ctx = cv.getContext("2d");
        let startX = 0;
        let startY = 0;

        cv.width = this.canvas.width;
        cv.height = this.canvas.height;

        const { x1, y1, x2, y2 } = this.getDirtyRegion();
        if (x1 > x2 || y1 > y2) {
            return null;
        }

        cv.width = x2 - x1 + 1;
        cv.height = y2 - y1 + 1;

        startX = x1;
        startY = y1;

        ctx.fillStyle = this.padColor;
        ctx.fillRect(0, 0, cv.width, cv.height);

        ctx.drawImage(this.canvas, startX, startY, cv.width, cv.height, 0, 0, cv.width, cv.height);
        return cv.toDataURL("image/png");
    }

    getDirtyRegion() {
        const imgData = this.context2d.getImageData(0, 0, this.canvas.width, this.canvas.height);
        const pixels = imgData.data;
        let minX = this.canvas.width;
        let minY = this.canvas.height;
        let maxX = -1;
        let maxY = -1;

        for (let i = 0; i < pixels.length; i += 4) {
            const x = (i / 4) % this.canvas.width;
            const y = Math.floor(i / 4 / this.canvas.width);
            const alpha = pixels[i + 3];

            if (alpha > 0) {
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
        }

        return { x1: minX, y1: minY, x2: maxX, y2: maxY };
    }
}