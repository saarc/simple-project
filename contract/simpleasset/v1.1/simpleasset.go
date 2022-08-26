package main


import (
	"encoding/json"
	"fmt"
	"time"
	"log"

	"github.com/golang/protobuf/ptypes"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing a car
type SmartContract struct {
	contractapi.Contract
}

// Car describes basic details of what makes up a car
type Asset struct {
	Key   string `json:"key"`
	Value  float64 `json:"value"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"Key"`
	Record *Asset
}

// history 결과 저장 구조체
type HistoryQueryResult struct {
	Record    *Asset    `json:"record"`
	TxId     string    `json:"txId"`
	Timestamp time.Time `json:"timestamp"`
	IsDelete  bool      `json:"isDelete"`
}

// CreateCar adds a new car to the world state with given details
func (s *SmartContract) Set(ctx contractapi.TransactionContextInterface, key string, value float64) error {
	asset := Asset{
		Key:   key,
		Value:  value,
	}

	assetAsBytes, _ := json.Marshal(asset)

	return ctx.GetStub().PutState(key, assetAsBytes)
}

// QueryCar returns the car stored in the world state with given id
func (s *SmartContract) Get(ctx contractapi.TransactionContextInterface, key string) (*Asset, error) {
	assetAsBytes, err := ctx.GetStub().GetState(key)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if assetAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", key)
	}

	asset := new(Asset)
	_ = json.Unmarshal(assetAsBytes, asset)

	return asset, nil
}

// ChangeCarOwner updates the owner field of car with given id in world state
func (s *SmartContract) Transfer(ctx contractapi.TransactionContextInterface, from string, to string, amount float64) error {
	fromAsset, err := s.Get(ctx, from)
	if err != nil {
		return err
	}
	toAsset, err := s.Get(ctx, to)
	if err != nil {
		return err
	}

	// 검증
	if fromAsset.Value - amount < 0 {
		return fmt.Errorf("not enough balance in from account: %s", from)
	}

	// 전송
		fromAsset.Value = fromAsset.Value - amount
		toAsset.Value = toAsset.Value + amount

	// (Marshal + PutState) * 2```
	fromAsBytes, _ := json.Marshal(fromAsset)
	ctx.GetStub().PutState(from, fromAsBytes)
	toAsBytes, _ := json.Marshal(toAsset)
	ctx.GetStub().PutState(to, toAsBytes)
	
	return nil
}

// GetHistory returns the chain of custody for an asset since issuance.
func (t *SmartContract) GetHistory(ctx contractapi.TransactionContextInterface, key string) ([]HistoryQueryResult, error) {
	log.Printf("GetHistory: ID %v", key)

	resultsIterator, err := ctx.GetStub().GetHistoryForKey(key)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var records []HistoryQueryResult
	for resultsIterator.HasNext() {
		response, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Asset
		if len(response.Value) > 0 {
			err = json.Unmarshal(response.Value, &asset)
			if err != nil {
				return nil, err
			}
		} else {
			asset = Asset{
				Key: key,
			}
		}

		timestamp, err := ptypes.Timestamp(response.Timestamp)
		if err != nil {
			return nil, err
		}

		record := HistoryQueryResult{
			TxId:      response.TxId,
			Timestamp: timestamp,
			Record:    &asset,
			IsDelete:  response.IsDelete,
		}
		records = append(records, record)
	}

	return records, nil
}

func main() {

	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil {
		fmt.Printf("Error create fabcar chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting fabcar chaincode: %s", err.Error())
	}
}
