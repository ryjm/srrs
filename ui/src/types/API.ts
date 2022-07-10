import SeerApi from './SeerApi'
import { Urbit } from '@urbit/http-api';
import SeerApiType from './SeerApi';
export declare interface APIType {
    seer: SeerApiType;
    upi: Urbit;
    constructor(upi: Urbit, seer: SeerApiType)
}
export default APIType;