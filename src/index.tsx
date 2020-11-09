import React, { ReactPropTypes } from 'react';
import {
  HostComponent,
  NativeModules,
  requireNativeComponent,
} from 'react-native';

type CustomuisdkType = {
  /**
   * This function show dialog to ask user permision to fetch authcode
   * @param clientId {string} unique id give to each merchant
   * @param mid {string} merchant id
   * @return {Promise<string>} Returns authcode
   */

  fetchAuthCode(clientId: string, mid: string): Promise<any>;

  /**
   * This function check that paytm app is installed or not
   * @return {Promise<boolean>} Returns installed - true or not -false
   */

  isPaytmAppInstalled(): Promise<boolean>;

  /**
   * @param mid {string} merchant id
   * @return {Promise<boolean>} Returns if has payment methods - true or not -false
   */

  checkHasInstrument(mid: string): Promise<boolean>;

  /**
   * @param mid {string} merchant id
   * @param orderId {string} order id
   * @param txnToken {string} transaction token
   * @param amount {string} transaction amount
   * @param isStaging {boolean} staging or production
   * @param callbackUrl {string} callback url only required for custom url page
   */

  initPaytmSDK(
    mid: string,
    orderId: string,
    txnToken: string,
    amount: string,
    isStaging: boolean,
    callbackUrl: string
  ): void;

  /**
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @return {Promise<any>} Returns object of response
   */

  goForWalletTransaction(paymentFlow: string): Promise<any>;

  /**
   * @param cardNumber {string} card number
   * @param cardExpiry {string} card expiry
   * @param cardCvv {string} card cvv
   * @param cardType {string} card type debit or credit
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @param channelCode {string} bank channel code
   * @param issuingBankCode {string} issuing bank code
   * @param emiChannelId {string} emi plan id
   * @param authMode {string} authentication mode 'otp' 'pin'
   * @param saveCard {boolean} save card for next time
   * @return {Promise<any>} Returns object of response
   */

  goForNewCardTransaction(
    cardNumber: string,
    cardExpiry: string,
    cardCvv: string,
    cardType: string,
    paymentFlow: string,
    channelCode: string,
    issuingBankCode: string,
    emiChannelId: string,
    authMode: string,
    saveCard: boolean
  ): Promise<any>;

  /**
   * @param cardId {string} card id of saved card
   * @param cardCvv {string} card cvv
   * @param cardType {string} card type  debit or credit
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @param channelCode {string} bank channel code
   * @param issuingBankCode {string} issuing bank code
   * @param emiChannelId {string} emi plan id
   * @param authMode {string} authentication mode 'otp' 'pin'
   * @return {Promise<any>} Returns object of response
   */

  goForSavedCardTransaction(
    cardId: string,
    cardCvv: string,
    cardType: string,
    paymentFlow: string,
    channelCode: string,
    issuingBankCode: string,
    emiChannelId: string,
    authMode: string
  ): Promise<any>;

  /**
   * @param netBankingCode {string} bank channel code
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @return {Promise<any>} Returns object of response
   */

  goForNetBankingTransaction(
    netBankingCode: string,
    paymentFlow: string
  ): Promise<any>;

  /**
   * @param upiCode {string} upi code
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @param saveVPA {boolean} save vpa for future transaction
   * @return {Promise<any>} Returns object of response
   */

  goForUpiCollectTransaction(
    upiCode: string,
    paymentFlow: string,
    saveVPA: boolean
  ): Promise<any>;

  /**
   * @return {Promise<any>} Returns upi app list names
   */

  getUpiIntentList(): Promise<any>;

  /**
   * @param appName {string} upi app name
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @return {Promise<any>} Returns object of response
   */

  goForUpiIntentTransaction(appName: string, paymentFlow: string): Promise<any>;

  /**
   * @param vpaName {string} vpa name
   * @param paymentFlow {string} payment type NONE, ADDANDPAY
   * @param bankAccountJson {{}} bank account json object
   * @param merchantDetailsJson {{}} merchant detail json
   * @return {Promise<any>} Returns object of response
   */

  goForUpiPushTransaction(
    paymentFlow: string,
    bankAccountJson: {},
    vpaName: string,
    merchantDetailsJson: {}
  ): Promise<any>;

  /**
   * @param vpaName {string} vpa name
   * @param bankAccountJson {{}} bank account json object
   * @return {Promise<any>} Returns object of response
   */

  fetchUpiBalance(bankAccountJson: {}, vpaName: string): Promise<any>;

  /**
   * @param vpaName {string} vpa name
   * @param bankAccountJson {{}} bank account json object
   * @return {Promise<any>} Returns object of response
   */

  setUpiMpin(bankAccountJson: {}, vpaName: string): Promise<any>;

  /**
   * @param cardSixDigit {string} card starting six digit
   * @param tokenType {string} token type ACCESS or TXN_TOKEN
   * @param token {string} token fetch from api
   * @param mid {string} merchant id
   * @param referenceId {string} reference id
   * @return {Promise<any>} Returns object of response
   */

  getBin(
    cardSixDigit: string,
    tokenType: string,
    token: string,
    mid: string,
    referenceId?: string
  ): Promise<any>;

  /**
   * @param tokenType {string} token type ACCESS or TXN_TOKEN
   * @param token {string} token fetch from api
   * @param mid {string} merchant id
   * @param orderId {string} order id required only if token type is TXN_TOKEN
   * @param referenceId {string} reference id required only if token type is ACCESS
   * @return {Promise<any>} Returns object of response
   */

  fetchNBList(
    tokenType: string,
    token: string,
    mid: string,
    orderId?: string,
    referenceId?: string
  ): Promise<any>;

  /**
   * @param channelCode {string} bank channel code
   * @param cardType {string} card type debit or credit
   * @return {Promise<any>} Returns object of response
   */

  fetchEmiDetails(channelCode: string, cardType: string): Promise<any>;

  /**
   * @return {Promise<any>} Returns last successfully used net backing code
   */

  getLastNBSavedBank(): Promise<any>;

  /**
   * @return {Promise<any>} Returns last successfully used vpa code
   */

  getLastSavedVPA(): Promise<any>;

  /**
   * @param clientId {string} unique id give to each merchant
   * @param authCode {string} fetched auth code
   * @return {Promise<any>} Returns last successfully used vpa code
   */

  isAuthCodeValid(clientId: string, authCode: string): Promise<any>;

  /**
   * @return {Promise<any>} Returns current environment
   */

  getEnvironment(): Promise<string>;

  /**
   * @param environment {string} setting environment PRODUCTION or STAGING
   */

  setEnvironment(environment: string): void;
};

const { PaytmCustomuisdk } = NativeModules;

export default PaytmCustomuisdk as CustomuisdkType;

var AuthCheckBox: HostComponent<any> = requireNativeComponent(
  'PaytmConsentCheckBox'
);

export class PaytmConsentCheckBox extends React.Component<any> {
  constructor(props: ReactPropTypes) {
    super(props);
    this._onChange = this._onChange.bind(this);
  }
  _onChange = (event: any) => {
    let { value } = event.nativeEvent;
    console.log(value);
    this.props.onChange(value);
  };

  render() {
    return (
      <AuthCheckBox
        {...this.props}
        style={{ flex: 1, padding: 24 }}
        onCheckChange={this._onChange}
      />
    );
  }
}
