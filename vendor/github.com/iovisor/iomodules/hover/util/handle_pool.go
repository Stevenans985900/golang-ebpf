// Copyright 2015-2016 PLUMgrid
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package util

import (
	"fmt"
	"github.com/willf/bitset"
)

// HandlePool is used to contain a sequential list of integer handles. Storage is a bit set.
type HandlePool struct {
	bitset.BitSet
}

// NewHandlePool returns a new handle pool with size entries available.
func NewHandlePool(size uint) *HandlePool {
	handles := &HandlePool{}
	// make sure ids is big enough, triggers extendSetMaybe
	handles.Set(size - 1).Clear(size - 1)
	// turn all the bits on
	handles.InPlaceUnion(handles.Complement())
	return handles
}

// Acquire returns the lowest available id in the pool, or error if exhausted.
func (handles *HandlePool) Acquire() (int, error) {
	handle, ok := handles.NextSet(0)
	if !ok {
		return -1, fmt.Errorf("HandlePool: pool empty")
	}
	handles.Clear(handle)
	return int(handle + 1), nil
}

// Release returns the id back into the pool
func (handles *HandlePool) Release(handle int) {
	handles.Set(uint(handle - 1))
}
