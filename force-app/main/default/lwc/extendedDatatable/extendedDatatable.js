import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';

import comboboxTemplate from './comboboxTemplate.html';
import comboboxEditTemplate from './comboboxEditTemplate.html';
import imageTemplate from './imageTemplate.html';
import richTextTemplate from './richTextTemplate.html';



export default class ExtendedDatatable extends LightningDatatable {

    static customTypes = {
        combobox: {
            template: comboboxTemplate,
            editTemplate: comboboxEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant', 'name']
        },
        image: {
            template: imageTemplate,
            standardCellLayout: true,
            typeAttributes: ['src', 'alt', 'title', 'width', 'height', 'object-fit', 'context']
        },
        richText: {
            template: richTextTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };

}